
 # NOME: Rute Lopes Pinto
 # NOME: Kananda Matos Dos Santos
 
 # Projeto Final - Aplicativo de To-Do List em Flutter

 # Definição do Projeto
Como parte do trabalho final da disciplina **Usabilidade, Web, Mobile e Games**, será desenvolvido um aplicativo mobile utilizando Flutter. O objetivo principal do aplicativo é ajudar os usuários a gerenciar suas tarefas diárias e lembretes de maneira eficiente e intuitiva.

---

# Objetivo
- Especificar e prototipar um aplicativo de to-do list.
- Desenvolver o aplicativo com foco em usabilidade, desempenho e segurança.

---

# Funcionalidades do Aplicativo

1. # Gerenciamento de Tarefas
- **Adicionar Tarefas**: Criar novas tarefas com título, descrição, data e hora de vencimento.
- **Editar Tarefas**: Alterar informações das tarefas existentes.
- **Excluir Tarefas**: Remover tarefas desnecessárias.
- **Marcar como Concluída**: Sinalizar tarefas finalizadas.
- **Categorias**: Organizar tarefas em categorias personalizadas.

2. Gerenciamento de Lembretes
- **Adicionar Lembretes**: Criar lembretes com título, descrição, data e hora.
- **Editar Lembretes**: Modificar informações dos lembretes.
- **Excluir Lembretes**: Remover lembretes que não são mais necessários.
- **Notificações**: Enviar lembretes aos usuários no horário agendado.

3. # Interface do Usuário
- **Design Intuitivo**: Interface amigável e fácil de usar.
- **Tema Claro e Escuro**: Suporte a temas claro e escuro.
- **Pesquisa**: Busca por título ou descrição de tarefas e lembretes.

---

 Requisitos Técnicos

# Plataforma
- Desenvolvido em **Flutter**, com compatibilidade para Android e iOS.

# Banco de Dados
- **SQLite** para armazenamento local de dados.
- Suporte opcional para sincronização com a nuvem.

### Notificações
- Utilização de notificações locais para lembretes.

---

## Requisitos de Desempenho
- **Responsividade**: Adaptado para diferentes tamanhos de tela.
- **Otimização**: Garantir rápido desempenho e eficiência.

---

## Requisitos de Segurança
- **Autenticação**: Login com e-mail/senha e suporte à autenticação social.
- **Privacidade**: Armazenamento seguro e privado dos dados do usuário.

---

## Primeira Tarefa: Documento de Especificação

### Objetivo
Desenvolver um documento contendo:
1. Protótipos de tela.
2. Lista de pelo menos 5 heurísticas de Nielsen, com explicação de como serão implementadas usando os widgets do Flutter.

### Protótipos de Tela
Os protótipos devem incluir:
- **Tela de Login**
- **Tela de Registro**
- **Tela Principal (Lista de Tarefas)**
- **Tela de Adicionar/Editar Tarefa**
- **Tela de Configurações**

### Heurísticas de Nielsen e Implementação com Flutter

#### 1. Visibilidade do Status do Sistema
- **Descrição**: Informar os usuários sobre o que está acontecendo, com feedback apropriado em tempo real.
- **Implementação**: Utilizar `SnackBar` ou `ProgressIndicator` para exibir feedback sobre ações.

#### 2. Correspondência entre o Sistema e o Mundo Real
- **Descrição**: Utilizar linguagem acessível e próxima ao usuário.
- **Implementação**: Widgets como `Text` e `IconButton` com ícones e textos compreensíveis.

#### 3. Controle e Liberdade do Usuário
- **Descrição**: Permitir que os usuários revertam ações e saiam de estados indesejados.
- **Implementação**: Adicionar botões de "Cancelar" com `ElevatedButton` ou "Undo" com `Snackbar`.

#### 4. Consistência e Padrões
- **Descrição**: Seguir convenções da plataforma e manter consistência no design.
- **Implementação**: Utilizar `MaterialApp` com temas consistentes.

#### 5. Prevenção de Erros
- **Descrição**: Prevenir problemas com validações e feedback antes que ocorram.
- **Implementação**: Usar `TextFormField` com validação.

---

## Professores
- **Stella Dornelas**
- **Alexandre Montanha**
