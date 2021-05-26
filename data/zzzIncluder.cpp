#include <fstream>
#include <iostream>
#include <vector>

using namespace std;

vector<string>* include(string file_name) {
	vector<string> file;
	ifstream in(file_name);
	string line;
	vector<string>* ret = new vector<string>();
	while (getline(in, line)) {
		file.push_back(line);
	}
	for (int i = 0; i < file.size(); i++) {
		if (file[i].length() >= 8 && file[i].substr(0, 8) == "#include") {
			string name = file[i].substr(9, string::npos);
			name = name.substr(1, name.length() - 2);
			vector<string>* included_p = include(name);
			vector<string> included = *included_p;
			delete included_p;
			for (string s : included) {
				ret->push_back(s);
			}
		} else {
			ret->push_back(file[i]);
		}
	}
	return ret;
}

int main(int argc, char* args[]) {
	vector<string> v = *include(args[1]);
	ofstream writer(args[2]);
	for (string s : v) {
		writer << s << endl;
	}
	writer.close();
}