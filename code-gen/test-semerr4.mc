//OPIS: pristupanje nepostojecem atributu
struct Book{
	int c;
	int b;
};

struct Book b;

int main(){
	b.m=5;
	return 0;
}
