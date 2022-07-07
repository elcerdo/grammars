#include <fblist.h>

#include <spdlog/spdlog.h>

int main(int argc, char* argv[])
{
		spdlog::info("coucou");

		for (size_t kk = 0; kk < 20; kk++) {
				spdlog::critical("{:04d} =============",
          kk);
				const auto ret = fblist::run_parser(kk);
        if (ret) spdlog::info("OK GOT {}", *ret);
        else spdlog::info("ERROR");
		}

		return 0;
}
