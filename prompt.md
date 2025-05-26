Analise o diretório local, que é a raiz do meu fork do Chatwoot (leomeirae/chatwoot), e execute as seguintes tarefas para construir uma imagem Docker e publicá-la no GitHub Container Registry (GHCR):

Construção da Imagem Docker:

Identifique e utilize o Dockerfile principal presente no diretório raiz do projeto (ou no subdiretório apropriado, como docker/, se for o caso para a imagem da aplicação Chatwoot).

Construa a imagem Docker a partir deste Dockerfile.

Nomeie e etiquete (tag) a imagem para o GitHub Container Registry (GHCR) usando o seguinte formato: ghcr.io/leomeirae/chatwoot:custom-v1. (Se desejar, pode sugerir uma tag mais específica ou me perguntar qual usar, mas custom-v1 serve como um bom ponto de partida).

Login no GitHub Container Registry (GHCR):

Antes de tentar publicar, será necessário fazer login no GHCR. Por favor, me solicite:

Meu nome de usuário do GitHub (que é leomeirae).

Um Personal Access Token (PAT) do GitHub com as permissões necessárias.

Se eu precisar gerar um novo PAT, por favor, me lembre que ele precisa do escopo write:packages (para "classic" tokens) ou, para "fine-grained tokens", permissão de "Read and Write" para "Packages" no repositório leomeirae/chatwoot.

Execute o comando docker login ghcr.io -u leomeirae --password-stdin (ou similar), utilizando o PAT que eu fornecer.

Publicação da Imagem Docker:

Após o login bem-sucedido no GHCR, publique a imagem ghcr.io/leomeirae/chatwoot:custom-v1 (ou a tag que foi definida no passo 1) para o GitHub Container Registry.

Informações para Atualização do docker-compose.yml:

Ao concluir a publicação, por favor, me forneça o nome completo e exato da imagem Docker que foi publicada (ex: ghcr.io/leomeirae/chatwoot:custom-v1). Esta informação será usada para atualizar as linhas image: nos serviços chatwoot_app e chatwoot_sidekiq do meu arquivo docker-compose.yml.

Lembrete sobre Migrações do Banco de Dados:

Por fim, me lembre que, após eu atualizar o docker-compose.yml com esta nova imagem e reimplantar o stack (por exemplo, via Portainer), será crucial executar as migrações do banco de dados (bundle exec rails db:migrate RAILS_ENV=production) dentro do contêiner chatwoot_app (usando sh -c "..." se necessário, devido ao erro anterior de bash not found).

Por favor, execute cada um destes passos de forma sequencial. Informe-me sobre o progresso, quaisquer comandos que você pretende executar (especialmente se diferirem dos exemplos), e quaisquer problemas ou informações adicionais que você precisar de mim durante o processo.