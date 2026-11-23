# 19. Cliente e Empresa em dois cadastros

Situação: **aprovada** (Pedro, 23/11/2026). Issue avant-core#458, milestone M14. Plano:
https://claude.ai/artifact/L3pdoVcvgku8soguXKdPPX.

Até aqui o cliente e a Empresa eram um registro só: a Groone cadastrava o cliente e a Empresa
nascia junto, sem dono, esperando o convite. Pedro decidiu separar os dois (23/11).

## O que ficou decidido

- **Cliente** (tabela `clients`): contato, dados fiscais, documentos, situação, limite de vagas
  (a Empresa segue o cliente), responsável, indicação, observações e `user_id`, a conta de login
  do cliente. Os clientes de antes têm o mesmo id da Empresa deles.
- **Empresa** (`companies`): `client_id` único (uma por cliente, vazio só na Groone) e dono
  sempre obrigatório.
- **Só o cliente cria a Empresa**, e uma só. A conta dele tem o papel **Publisher** (todas as
  permissões do painel do cliente mais criar a Empresa). Funcionário convidado não cria.
  Rota `POST /api/v1/auth/me/company`; `GET /auth/me` traz `can_create_company`. Cliente inativo
  ou banido não cria.
- **Sem troca de dono**: a Empresa fica sempre com o cliente que a criou. Saíram o botão
  "Trocar dono", a rota `POST /internal/clients/{id}/owner`, o `change_owner` do core e a
  permissão `internal.owner.change` (79 permissões).
- **Networks são do cliente** (`networks.client_id`); a Empresa herda. A equipe pode guardar um
  network code num cliente que ainda não tem Empresa (tabela `reserved_networks`, rotas
  `POST /internal/networks/reserved` e `DELETE /internal/networks/reserved/{id}`); quando o
  cliente cria a Empresa, os códigos viram networks confirmadas dela e a sincronização começa.
  Um código guardado não serve para outro cliente (função `avant_network_code_reserved_elsewhere`,
  que vê por cima do RLS).
- **Convite do cliente**: o convite de dono vai para o cliente (`invitations.client_id`), sem
  Empresa criada antes. Aceitar liga a conta ao cliente e deixa ele ativo.
- **Comissão "cliente novo"** (decisão 09): o prazo abre quando o cliente cria a Empresa, não
  mais quando a Groone cadastra o cliente.
- **Empresas sem dono** serão apagadas por uma migration seguinte, que também deixa o dono
  NOT NULL.

## Migrations

0070 (`company_profiles` vira `clients`), 0071 (nome, conta, situação, vagas e data de saída no
cliente), 0072 (sai a troca de dono), 0073 (convite do cliente), 0074 (`reserved_networks`, com
RLS pelo cliente), 0075 (cliente para as Empresas antigas sem cadastro e a função da reserva).

## Painel

- Interno: a página do cliente mostra "Aguardando a Empresa" e as networks guardadas enquanto
  ele não cria; documentos e observações aparecem quando a Empresa existe. A lista de Empresas
  mostra os clientes sem Empresa com o link para o cliente.
- Cliente: em Início, a conta sem Empresa vê o cartão "Crie a sua Empresa".
- O dono aparece com o papel "Publisher".
