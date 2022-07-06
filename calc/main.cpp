#include <assembly.h>

#include <iostream>

using std::cout;
using std::endl;

int main(int argc, char* argv[])
{
		cout << "coucou" << endl;

		for (size_t kk=0; kk<5; kk++) {
				cout << "=============" << endl;
				const auto ret = yy_asm::run_parser(kk);
				cout << (ret ? "ERROR" : "OK") << endl;
		}

		return 0;
}
