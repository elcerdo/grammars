#include <assembly.h>

#include <iostream>

using std::cout;
using std::endl;

int main(int argc, char* argv[])
{
		cout << "coucou" << endl;

		for (size_t kk=0; kk<5; kk++) {
				cout << "=============" << endl;
				const auto ret = assembly::run_parser(kk);
				cout << (ret ? "OK" : "ERROR") << endl;
        if (ret) cout << "GOT " << *ret << endl;
		}

		return 0;
}
