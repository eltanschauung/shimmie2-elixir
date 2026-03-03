```
     _________.__     .__                   .__         ________
    /   _____/|  |__  |__|  _____    _____  |__|  ____  \_____  \
    \_____  \ |  |  \ |  | /     \  /     \ |  |_/ __ \  /  ____/
    /        \|   Y  \|  ||  Y Y  \|  Y Y  \|  |\  ___/ /       \
   /_______  /|___|  /|__||__|_|  /|__|_|  /|__| \___  >\_______ \
           \/      \/           \/       \/          \/         \/

```

# Shimmie re-written in Elixir + Phoenix

This is Shimmie2 by Shish & co. rewritten in the Elixir language for a personal project. This is made to be used with the Phoenix Framework and requires PostGreSql (replacing Sqlite in Shimmie2). I've made some personal changes from the original for loading and modularity that I find more favorable; see [Gyate Booru](https://gyate.net) for a demo.

# Requirements

- Elixir and Erlang/OTP
- PostgreSQL
- Basic build tools: `build-essential`, `git`, `curl`
- Clone this repository and run from `phoenix_rewrite/`
- Install deps and DB setup: `mix deps.get` and `mix ecto.setup`
- Start locally: `mix phx.server`
- Production runtime: `MIX_ENV=prod mix release`
- Optional launcher script: `start_booru_phoenix.sh` (default port `4001`)
- Environment variables for secrets/config (for example `DATABASE_URL`, `SECRET_KEY_BASE`)

# Licence

All code is released under the [GNU GPL Version 2](https://www.gnu.org/licenses/gpl-2.0.html) unless mentioned otherwise.

If you give shimmie to someone else, you have to give them the source (which
should be easy, as PHP is an interpreted language...). If you want to add
customisations to your own site, then those customisations belong to you,
and you can do what you want with them.

# Original Documentation & Links

* [Install straight on disk](https://github.com/shish/shimmie2/wiki/Install)
* [Install in docker container](https://github.com/shish/shimmie2/wiki/Docker)
* [Upgrade process](https://github.com/shish/shimmie2/wiki/Upgrade)
* [Advanced config](./core/Config/SysConfig.php)
* [Developer notes](https://github.com/shish/shimmie2/wiki/Development-Info)
* [High-performance notes](https://github.com/shish/shimmie2/wiki/Performance)