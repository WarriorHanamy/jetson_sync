# Project Agent Guidelines

## Remote Execution

This project uses Syncthing for bidirectional sync between host and Jetson device.
Use the remote execution wrappers instead of direct commands:

```bash
# Remote catkin_make for specific package (creates src/ symlink automatically)
./sync/remote-catkin-make -p simple_px4_odom

# Remote catkin_make with additional args
./sync/remote-catkin-make -p <package_name> -- -j4

# Remote VIO session (starts tmux on device, logs sync to host)
./sync/remote-run-vio
```

Log locations:
- `logs/catkin/` - Build logs
- `logs/tmux/` - Runtime session logs

Device config: `sync/.env` (DEVICE_IP, DEVICE_USER, SSH_KEY, etc.)
