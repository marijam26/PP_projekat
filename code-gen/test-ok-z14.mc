//OPIS: dodela atributu vrednost drugog atributa
//RETURN: 50

struct Book{
	int c;
	int b;
};

struct Book1{
	int aa;
	int bb;
};

struct Book boo;
struct Book1 boo1;

int main() {
    int a;
    boo.c=25;
    boo1.aa=boo.c;
    a = boo.c + boo1.aa;
    return a;

}


