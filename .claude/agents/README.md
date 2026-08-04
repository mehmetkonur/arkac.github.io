# Ajanlar (Subagents)

Bu klasör, Claude Code için uzman **subagent** tanımlarını içerir. Her `.md`
dosyası, YAML frontmatter + kişilik/görev tanımı taşıyan bir ajandır ve Claude
Code tarafından `Agent` aracıyla otomatik olarak kullanılabilir.

## Kaynak

Ajanlar [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents)
deposundan alınmıştır (MIT lisansı — bkz. `LICENSE`). Toplam 286 ajan, 18 bölüm
altında düzenlenmiştir.

## Bölümler

`academic`, `design`, `engineering`, `finance`, `game-development`, `gis`,
`healthcare`, `marketing`, `paid-media`, `product`, `project-management`,
`sales`, `security`, `spatial-computing`, `specialized`, `strategy`, `support`,
`testing`.

Bölüm eşlemesi için `divisions.json` dosyasına bakın.

## Kullanım

Claude Code, `.claude/agents/` altındaki tüm alt klasörleri tarar. Bir görevde
ilgili ajan otomatik seçilebilir; ya da adıyla çağırabilirsiniz. Örneğin bu
web projesi için `engineering/engineering-frontend-developer.md` veya
`design/design-ui-designer.md` uygundur.
