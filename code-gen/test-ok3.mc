//OPIS: instanciranje dve strukture
//RETURN: 12

struct Book{
	int c;
	int b;
};


struct Book book1;

int foo(int a){
	return a;
}

int main() {
	int bla;
	book1.c=12;
	bla = foo(book1.c);
	return bla;
}
