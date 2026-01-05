# Managing libs/hbb_common Submodule

## Current Status

`libs/hbb_common` is a **Git submodule** pointing to:
```
https://github.com/rustdesk/hbb_common
```

**Your config.rs changes are NOT committed** - kept locally on each machine.

---

## Config.rs Changes by Branch

### Both Branches (windows_android_build + linux_build)
```rust
// Line 46 - macOS org
pub static ref ORG: RwLock<String> = RwLock::new("com.xconnect".to_owned());

// Line 61 - App name
pub static ref APP_NAME: RwLock<String> = RwLock::new("XConnect".to_owned());

// Lines 66-71 - Enable direct IP access by default
pub static ref OVERWRITE_SETTINGS: RwLock<HashMap<String, String>> = {
    let mut map = HashMap::new();
    map.insert(keys::OPTION_DIRECT_SERVER.to_owned(), "Y".to_owned());
    map.insert(keys::OPTION_DIRECT_ACCESS_PORT.to_owned(), "12345".to_owned());
    RwLock::new(map)
};
```

### linux_build Only (Additional)
```rust
// 1. NEW FIELD in Config struct (around line 200)
pub struct Config {
    pub id: String,
    // ... existing fields ...
    // XConnect: Custom device name for linux_build branch
    #[serde(default, deserialize_with = "deserialize_string")]
    pub x_connect_device_name: String,  // ← ADD THIS FIELD
}

// 2. Make load() and store() public (around lines 572 and 615)
// XConnect: Made public for x_connect_device_name getter/setter in flutter_ffi.rs
pub fn load() -> Config {   // ← Change from `fn` to `pub fn`

// XConnect: Made public for x_connect_device_name getter/setter in flutter_ffi.rs
pub fn store(&self) {       // ← Change from `fn` to `pub fn`
```

**Why linux_build needs these:** The `src/flutter_ffi.rs` file has getter/setter functions:
```rust
pub fn get_x_connect_device_name() -> String {
    let config = hbb_common::config::Config::load();  // needs public load()
    config.x_connect_device_name.clone()
}

pub fn set_x_connect_device_name(value: String) {
    let mut config = hbb_common::config::Config::load();
    config.x_connect_device_name = value;
    hbb_common::config::Config::store(&config);  // needs public store()
}
```

---

## After Syncing Branches

When you rebase `linux_build` or `windows_android_build` onto master:

1. **Submodule pointer may change** - master may use a newer hbb_common commit
2. **Re-apply your config.rs changes** on each machine
3. **Test build:** `cargo build --release`

---

## LLM Prompt for Re-Applying

> I need to re-apply XConnect config.rs changes to libs/hbb_common/src/config.rs.
>
> Changes needed:
> 1. Line 46: `ORG = "com.xconnect"`
> 2. Line 61: `APP_NAME = "XConnect"`
> 3. Lines 66-71: `OVERWRITE_SETTINGS` with DIRECT_SERVER=Y, DIRECT_ACCESS_PORT=12345
> 4. (linux_build only) Line 183: Add `x_connect_device_name` field to Config struct
>
> Please show me the exact code to add/modify.

---

## Future Option: Fork the Submodule

If you want to commit config.rs changes properly:

1. Fork https://github.com/rustdesk/hbb_common
2. `git submodule set-url libs/hbb_common YOUR_FORK_URL`
3. Commit config.rs changes to your fork
4. Commit submodule pointer update in parent repo
