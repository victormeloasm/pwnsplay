#include <iostream>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <ctime>

using namespace std;

struct Produto {
    int id;
    char nome[50];
    float preco;
    int estoque;
    char descricao[200];  // campo grande, mas seguro
};

Produto catalogo[100];
int totalProdutos = 0;

void limparBuffer() {
    cin.ignore(1000, '\n');
}

void cadastrarProduto() {
    if (totalProdutos >= 100) {
        cout << "Catalogo cheio.\n";
        return;
    }
    
    Produto p;
    p.id = totalProdutos + 1;
    
    cout << "Nome do produto: ";
    cin.getline(p.nome, 50);
    
    cout << "Preco: ";
    cin >> p.preco;
    
    cout << "Estoque: ";
    cin >> p.estoque;
    limparBuffer();
    
    cout << "Descricao (max 199): ";
    cin.getline(p.descricao, 200);
    
    catalogo[totalProdutos++] = p;
    cout << "Produto cadastrado com ID " << p.id << "\n";
}

void listarProdutos() {
    cout << "\n" << string(80, '-') << endl;
    cout << left << setw(5) << "ID" << setw(30) << "Nome" << setw(10) << "Preco" << setw(10) << "Estoque" << "Descricao" << endl;
    cout << string(80, '-') << endl;
    for (int i = 0; i < totalProdutos; i++) {
        cout << left << setw(5) << catalogo[i].id
             << setw(30) << catalogo[i].nome
             << setw(10) << catalogo[i].preco
             << setw(10) << catalogo[i].estoque
             << catalogo[i].descricao << endl;
    }
    cout << string(80, '-') << "\n";
}

void buscarProduto() {
    char termo[50];
    cout << "Termo de busca (nome): ";
    cin.getline(termo, 50);
    
    bool achou = false;
    for (int i = 0; i < totalProdutos; i++) {
        if (strstr(catalogo[i].nome, termo)) {
            cout << "ID: " << catalogo[i].id << " | Nome: " << catalogo[i].nome
                 << " | Preco: " << catalogo[i].preco << " | Estoque: " << catalogo[i].estoque << endl;
            achou = true;
        }
    }
    if (!achou) cout << "Nao encontrado.\n";
}

void excluirProduto() {
    int id;
    cout << "ID do produto: ";
    cin >> id;
    limparBuffer();
    
    for (int i = 0; i < totalProdutos; i++) {
        if (catalogo[i].id == id) {
            for (int j = i; j < totalProdutos - 1; j++) {
                catalogo[j] = catalogo[j+1];
            }
            totalProdutos--;
            cout << "Produto excluido.\n";
            return;
        }
    }
    cout << "ID nao encontrado.\n";
}

// ========== FUNO VULNERVEL ==========
void processarComando() {
    char buffer[64];      // buffer pequeno na pilha
    char comando[200];    // entrada do usurio
    
    cout << "\n=== CONSOLE ADMIN (vulneravel) ===\n";
    cout << "Digite um comando (max 199 caracteres): ";
    cin.getline(comando, 200);
    
    // A FALHA: strcpy sem verificao de tamanho
    // copia 'comando' (at 199 bytes) para 'buffer' (64 bytes)
    strcpy(buffer, comando);
    
    cout << "Comando processado: " << buffer << endl;
    
    // Simula ao baseada no comando
    if (strcmp(buffer, "listar") == 0) {
        listarProdutos();
    } else if (strcmp(buffer, "help") == 0) {
        cout << "Comandos: listar, sair, help\n";
    } else {
        cout << "Comando desconhecido.\n";
    }
}

void relatorioVendas() {
    // funo dummy
    cout << "=== RELATORIO DE VENDAS ===\n";
    cout << "Total de produtos: " << totalProdutos << endl;
    cout << "Data: " << __DATE__ << " " << __TIME__ << endl;
}

void configurarSistema() {
    char opcao[10];
    cout << "Configuracoes: (1) Backup (2) Reset (3) Sair\n";
    cout << "Opcao: ";
    cin.getline(opcao, 10);
    
    if (strcmp(opcao, "1") == 0) {
        cout << "Backup simulado.\n";
    } else if (strcmp(opcao, "2") == 0) {
        cout << "Reset solicitado.\n";
    }
}

int main() {
    int opcao;
    
    cout << "========== SISTEMA DE ESTOQUE (BUFFER OVERFLOW) ==========\n";
    cout << "Versao 1.0\n\n";
    
    // Cadastros iniciais
    Produto p1 = {1, "Mouse", 29.90, 50, "Mouse optico USB"};
    Produto p2 = {2, "Teclado", 89.90, 30, "Teclado mecanico RGB"};
    Produto p3 = {3, "Monitor", 799.00, 10, "Monitor 24 polegadas"};
    catalogo[0] = p1; catalogo[1] = p2; catalogo[2] = p3;
    totalProdutos = 3;
    
    do {
        cout << "\n----------------------------------------\n";
        cout << "1 - Cadastrar produto\n";
        cout << "2 - Listar produtos\n";
        cout << "3 - Buscar produto\n";
        cout << "4 - Excluir produto\n";
        cout << "5 - Console Admin (VULNERAVEL)\n";
        cout << "6 - Relatorio de vendas\n";
        cout << "7 - Configuracoes\n";
        cout << "0 - Sair\n";
        cout << "Opcao: ";
        cin >> opcao;
        limparBuffer();
        
        switch(opcao) {
            case 1: cadastrarProduto(); break;
            case 2: listarProdutos(); break;
            case 3: buscarProduto(); break;
            case 4: excluirProduto(); break;
            case 5: processarComando(); break;
            case 6: relatorioVendas(); break;
            case 7: configurarSistema(); break;
            case 0: cout << "Encerrando.\n"; break;
            default: cout << "Opcao invalida.\n";
        }
    } while (opcao != 0);
    
    return 0;
}