local env = {

  name = "santoku-html",
  version = "0.0.2-1",
  variable_prefix = "TK_HTML",
  license = "MIT",
  public = true,

  dependencies = {
    "lua >= 5.1",
    "santoku >= 0.0.145-1",
    "lpeg >= 1.1.0-1",
  },

  test_dependencies = {
    "santoku-test >= 0.0.2-1",
    "luassert >= 1.9.0-1",
    "luacheck >= 1.1.0-1",
    "luacov >= 0.15.0-1",
  },

}

env.homepage = "https://github.com/treadwelllane/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  env = env,
}