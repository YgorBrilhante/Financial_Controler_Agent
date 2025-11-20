# Agente de Controle Financeiro e de Compromissos via Telegram

## Inspirado em alguns SaaS existentes no mercado resolvi fazer a minha versão de um agente de controle pessoal.

### O projeto consiste em um bot do Telegram que usando Inteligência Artificial entende a intenção do usuário (através de texto, audio ou imagem), classifica a intenção, aplica a ação solicitada e retorna ao usuário, podendo ser:
 * Transações:
   * Inserção de gastos ou receitas, sendo únicos ou recorrentes
 * Lembretes
   * Criação de lembretes e compromissos com data e horário
 * Categorias
   * Criação de categorias para serem enquadradas as transações
 * Consultas e Insights
   * Consultar a situação dos gastos e lembretes ou ter insights de acordo com a situação financeira atual
 * Gráficos
   * Solicitar gráficos para melhor visualização financeira
 * Crons - [não dependem da ação do usuário]
   * Fazem a verificação a cada minuto se há algum lembrete agendado e verificam todo dia se há alguma transação recorrente que precisa ser inserida na tabela de transações do mês para controle
##

## Tecnologias
* Telegram
* n8n
* Javascript
* PostgreSQL
* Redis
* OpenAI API
* QuickChart
<img src="https://github.com/user-attachments/assets/a1d625d3-951e-4760-a98c-a39445cb8a0b" width="350">
<img src="https://github.com/user-attachments/assets/ff450435-df8e-4824-8f63-a4a9f80469fa" width="350">

<!-- ![agente print 1](https://github.com/user-attachments/assets/a1d625d3-951e-4760-a98c-a39445cb8a0b) -->
<!-- ![agente print 2](https://github.com/user-attachments/assets/ff450435-df8e-4824-8f63-a4a9f80469fa) -->
