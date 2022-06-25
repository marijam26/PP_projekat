//OPIS: sabiranje dva atributa struktura
//RETURN: 35

struct Book{
	int c;
	int b;
};

struct Book1{
	int a;
	int f;
};

struct Book boo;

int main() {
    int a;
    boo.c=25;
    boo.b=10;
    a = boo.c + boo.b;
    return a;

}

