# Projeto Integração - Asimov Jr.

## Objetivo
Desenvolvimento de um Sistema de Gestão Integrada (ERP) voltado para as necessidades de controle e comunicação interna da Asimov Jr. O projeto atua como um hub central definitivo para resolver gargalos operacionais, descentralização de dados estratégicos e ruídos de comunicação. 

## Tecnologias Utilizadas
O ecossistema do projeto foi construído utilizando tecnologias modernas e confiáveis:
*   **Frontend Desktop:** Angular
*   **Frontend Mobile:** Flutter
*   **Banco de Dados & Backend:** Firebase
*   **Prototipagem & UI/UX:** Figma
*   **Metodologia Ágil:** Scrum

## Funcionalidades Principais

O sistema possui controle de acessos (permissões) baseado em hierarquia (Membros, Gerentes e Diretores), garantindo a segurança das informações. O login é restrito a contas com o domínio `@asimovjr.com.br`.

### Sistema Desktop (Gestão Administrativa)
Focado no controle de gestão e cadastros completos:
*   **Home/Dashboard:** Visão geral dos KPIs estratégicos, metas do Portal BJ e andamento dos projetos.
*   **Gestão Financeira:** Controle de entradas, saídas, módulo de envio de Nota Fiscal (upload de PDF/imagem) e relatórios de fluxo de caixa (Restrito à Diretoria).
*   **Gestão de Projetos:** Cadastro, atribuição de membros, definição de prazos, valores e acompanhamento de status.
*   **Gestão de Pessoas:** Controle de status (Ativo/Inativo), cargos e hierarquia.
*   **Comunicação:** Calendário de eventos/entregas e Feed Social para atualizações corporativas.

###  Aplicativo Mobile (Comunicação e Operação)
Focado no uso diário e fortalecimento da cultura interna:
*   **Feed Social Interativo:** Criação de postagens em texto e interação (likes) entre os membros.
*   **Acompanhamento Rápido:** Visualização de KPIs na Home e acompanhamento de projetos.
*   **Calendário Integrado:** Visualização em agenda de reuniões e entregas.

##  Equipe Desenvolvedora
*   Miguel Cortez Cavalcante
*   Matheus Motta Soriano
*   Ana Luísa Silva Alves
*   isadora eduarda costa franco
*   Giovana Fróes e Silva
*   Matheus Alcântara Pereira

##  Como Executar o Projeto

### Pré-requisitos
Certifique-se de ter os seguintes ambientes instalados em sua máquina:
*   [Node.js](https://nodejs.org/) e [Angular CLI](https://angular.io/cli)
*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   Conta configurada no Firebase com as credenciais do projeto.

### Rodando o ambiente Desktop (Angular)
```bash
# Clone o repositório Desktop
git clone <url-do-repositorio-desktop>

# Acesse a pasta do projeto
cd desktop-asimov-jr

# Instale as dependências
npm install

# Execute o servidor local
ng serve 
