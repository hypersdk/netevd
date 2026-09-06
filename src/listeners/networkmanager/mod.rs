// Copyright 2026 Zyvor AI Labs · https://zyvor.dev
// SPDX-License-Identifier: Apache-2.0

//! NetworkManager DBus listener

pub mod dbus;

// Re-export the main listener function
pub use dbus::listen_networkmanager;
