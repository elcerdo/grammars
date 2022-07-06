#include <assembly.h>

#include <iostream>

using std::cout;
using std::endl;

int main(int argc, char* argv[])
{
		cout << "coucou" << endl;

		for (size_t kk=0; kk<5; kk++) {
				cout << "=============" << endl;
				const auto ret = run_asm_parser(kk);
				cout << (ret ? "ERROR" : "OK") << endl;
		}

		return 0;
}


