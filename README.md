# Wonky’s Keep Containers — World Placement & Management
Preview https://www.youtube.com/watch?v=FtHQJvCCJ5s
A Qbox conversion of [Swkeep’s keep-containers](https://github.com/swkeep/keep-containers), based on version 1.2.0. Place persistent storage containers outside the original depot zones and manage them in-game.

- `Config.PlaceAnywhere = true` enables placement outside configured depots, subject to the placement checks.
- Nearby containers stream within the configured distance, which defaults to 150 metres.
- Container interactions include storage access, ownership transfer and locking. Authorized staff have additional management actions. The resource creates tables for container records and access logs.

## Installation

1. Install and start `qbx_core`, `ox_lib`, `oxmysql`, `ox_inventory` and `ox_target` before this resource.
2. Copy the contents of `inventoryImages/` to `ox_inventory/web/images/`. Add these entries inside the returned table in `ox_inventory/data/items.lua`:

   ```lua
   ['container_green_small'] = { label = 'Small Green Container', weight = 5, stack = false, close = true },
   ['container_blue_mid'] = { label = 'Mid Blue Container', weight = 15, stack = false, close = true },
   ['container_old_mid'] = { label = 'Mid Old Container', weight = 15, stack = false, close = true },
   ['container_white_mid'] = { label = 'Mid White Container', weight = 15, stack = false, close = true },
   ['containerboltcutter'] = {
       label = 'Bolt Cutter', weight = 1, stack = false, close = false,
       client = { image = 'boltcutter.png' },
   },
   ```

3. Review `config.lua`. Add your own staff Discord IDs to `Config.super_users` if using that allowlist, or configure the ACE checks used by your server. Check `Config.bolt_cutter` for job and grade access.
4. Keep the resource folder named `keep-containers`, then add `ensure keep-containers` after its dependencies. The database tables are created at startup. Back up existing tables before replacing an installed copy.
5. Test placement outside a depot, storage access after reconnecting, and management permissions with both a staff and a regular player. Use `/kcperm` to print permission diagnostics to the server console.

## Credits and license

Original resource by Swkeep. Qbox conversion and world placement customization by Wonky’s World. The original notices and [GPL-3.0 license](LICENSE) are included. The original documentation is preserved in [UPSTREAM-README.md](UPSTREAM-README.md).
