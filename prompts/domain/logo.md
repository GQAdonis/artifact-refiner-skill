# Logo Refiner Module

Load brand constraints from:
- travisjames-ai-brand-guide.html  [oai_citation:2‡travisjames-ai-brand-guide.html](sediment://file_00000000af7071f79728de34915908e4)
- palette.html  [oai_citation:3‡palette.html](sediment://file_00000000d2bc71f7942c0f3ea9dea376)

Extract:
- Primary brand color
- Dark mode primary
- Neutral backgrounds
- Typography hierarchy

Requirements:
- Generate SVG first
- Then rasterize to PNG in sizes:
  16, 32, 48, 64, 128, 192, 256, 512
- Generate wordmark + icon + app icon
- Generate showcase HTML referencing assets
- Update artifact_manifest.json