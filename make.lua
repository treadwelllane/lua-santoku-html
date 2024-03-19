local env = {

  name = "santoku-html",
  version = "0.0.15-1",
  variable_prefix = "TK_HTML",
  license = "MIT",
  public = true,

  dependencies = {
    "lua >= 5.1",
    "santoku >= 0.0.203-1",
  },

  test = {
    dependencies = {
      "luacov >= 0.15.0-1",
      "santoku-fs >= 0.0.30-1",
    }
  },

}

env.homepage = "https://github.com/treadwelllane/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  type = "lib",
  env = env,
}
