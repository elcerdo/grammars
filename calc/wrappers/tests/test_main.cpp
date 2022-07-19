#define CATCH_CONFIG_RUNNER
#include <catch2/catch.hpp>

#include <spdlog/spdlog.h>

int main(int argc, char* argv[]) {
  Catch::Session session;
  int log_level = 2;

  auto cli = session.cli()
  | Catch::clara::Opt(log_level, "log level")["--log-level"]("Log level");

  session.cli(cli);

  if (auto ret = session.applyCommandLine(argc, argv)) {
    return ret;
  }

  log_level = std::max(0, std::min(6, log_level));
  spdlog::set_level(static_cast<spdlog::level::level_enum>(log_level));

  const auto session_ret = session.run();

  return session_ret;
}
