---
name: avant-fluxo-de-trabalho
description: Use no começo de qualquer tarefa no Groone Avant. Mostra como achar a issue, criar a branch, rodar as checagens, abrir o PR para develop, fazer o merge e fechar a issue.
---

# Fluxo de trabalho do Groone Avant

Toda demanda é uma issue com milestone no repositório certo. Nada de trabalho sem issue: se o pedido não tem uma, crie a issue antes (título em português, contexto, checklist de "pronto quando", milestone).

## 1. Entender

1. Leia `docs/contexto.md` (produto, decisões, estado) e o `CLAUDE.md` deste repositório.
2. Ache a issue: `gh issue list --repo PedroH3nri/<repo> --milestone "<milestone>"` e `gh issue view <N> --repo PedroH3nri/<repo>`.
3. Se a issue tem "Issues irmãs", a ordem é avant-core, depois avant-api e avant-worker, por fim avant-web. Não comece a tela antes da rota, nem a rota antes do caso de uso.
4. Decisão que muda o objetivo é do Pedro: pergunte uma vez, com recomendação, e siga com a recomendada enquanto ele não responde (se der para desfazer).

## 2. Fazer

```bash
git fetch origin develop:refs/remotes/origin/develop
git checkout -B feat/<assunto> origin/develop    # ou fix/<assunto>
```

Todo código segue a `avant-clean-code` (obrigatória). Siga também as skills do tipo de mudança deste repositório (veja `docs/skills/README.md`) e as do superpowers: `test-driven-development` para código, `systematic-debugging` para bug, `verification-before-completion` antes de dizer que terminou.

## 3. Checar

O avant-infra não tem CI. Rode a validação da skill `avant-deploy-vm` (`docker compose config` nos dois ambientes e `shellcheck`).

## 4. Entregar

- Commit em português, terminando com `Closes #N`.
- PR para `develop` pela API REST (o `gh pr create` pode falhar por causa do GraphQL):

```bash
gh api repos/PedroH3nri/<repo>/pulls -f base=develop -f head=<branch> \
  -f title="<título>" -F body=@corpo.md --jq '.number, .head.sha'
```

- Corpo do PR: `Closes #N`, o que muda e como foi testado.
- Merge (squash) em `develop` quando o CI passa e não há comentário pendente. `main` e produção são sempre do Pedro.
- O branch padrão é `main`, então o `Closes #N` não fecha a issue no merge em `develop`: feche à mão.

```bash
gh api -X PATCH repos/PedroH3nri/<repo>/issues/<N> -f state=closed -f state_reason=completed
```

- Marque os itens do checklist da issue que ficaram prontos e, se sobrou algo, abra uma issue nova com o que falta.

## Nunca

- Segredo no repositório, em issue ou em PR. Os valores ficam só nas VMs.
- Pular, desligar ou marcar como flaky um teste para o CI passar.
- Push direto em `develop` ou `main`, ou merge em `main`.
