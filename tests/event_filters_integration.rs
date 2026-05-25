#![cfg(target_os = "linux")]

// SPDX-License-Identifier: LGPL-3.0-or-later

use std::collections::HashMap;
use std::fs;
use std::io::Read;
use tempfile::TempDir;
use uuid::Uuid;

#[tokio::test]
async fn test_execute_scripts_respected_by_filters() {
    // Create a temporary script directory
    let td = TempDir::new().expect("tempdir");
    let script_dir = td.path().to_str().unwrap().to_string();

    // Output path (no dots to avoid validation pitfalls in the daemon)
    let output = format!("/tmp/netevd_test_{}", Uuid::new_v4().as_simple());

    // Create a simple script that writes ADDRESSES to the output file
    let script_path = td.path().join("01-test.sh");
    let script_content = format!("#!/bin/bash\necho \"$ADDRESSES\" > {}\nexit 0\n", output);
    tokio::fs::write(&script_path, script_content)
        .await
        .expect("write script");

    // Make it executable
    let mut perms = fs::metadata(&script_path).expect("meta").permissions();
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        perms.set_mode(0o755);
        fs::set_permissions(&script_path, perms).expect("chmod");
    }

    // Prepare environment values
    let mut env_vars = HashMap::new();
    env_vars.insert("ADDRESSES".to_string(), "1.2.3.4".to_string());
    env_vars.insert("LINK".to_string(), "eth0".to_string());
    env_vars.insert("STATE".to_string(), "routable".to_string());

    // Execute scripts in the directory (this should run our script)
    crate::system::execute::execute_scripts(&script_dir, env_vars)
        .await
        .expect("execute scripts");

    // Verify output file was created and contains the expected value
    let mut buf = String::new();
    fs::File::open(&output)
        .expect("open out")
        .read_to_string(&mut buf)
        .expect("read out");
    assert!(buf.trim() == "1.2.3.4");

    // Cleanup
    let _ = fs::remove_file(&output);
}

#[test]
fn test_event_filter_blocks_execution() {
    let filter_yaml = r#"
filters:
  - match_rule:
      interface_pattern: "eth*"
      event_type: "routable"
    action: ignore
"#;

    let filter = crate::filters::EventFilter::from_yaml(filter_yaml).expect("parse filter");

    let event = crate::filters::NetworkEvent {
        interface: "eth0".to_string(),
        event_type: "routable".to_string(),
        backend: "systemd-networkd".to_string(),
        addresses: Vec::new(),
        has_gateway: true,
        dns_servers: Vec::new(),
    };

    assert!(!filter.should_execute(&event));
}
