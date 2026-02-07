---
name: skill-fetcher
description: Agent Registryからスキル・サブエージェント・ワークフローを取得するブートストラップスキル。プロジェクト開始時に最初に読み込む。
---

# Skill Fetcher

Agent Registryからプロジェクトに必要なスキルを取得するためのスキル。

---

## 使用方法

### 基本フロー

```
1. ユーザーがプロジェクト要件を伝える
2. 要件を分析し、必要なスキルを特定
3. catalog.yamlを参照して推奨スキルを取得
4. 取得したスキルをプロジェクトに配置
```

---

## カタログ参照

カタログはこちら:
https://raw.githubusercontent.com/t2k2pp/agent-registry/main/catalog.yaml

### カタログの読み方

```yaml
# フレームワーク未指定時 → tech-stack-selectorを取得
recommendations:
  - keywords: [モバイルアプリ, アプリ開発]
    condition: "フレームワーク明示なし"
    suggest:
      core: [tech-stack-selector]

# Flutter指定時 → Flutter関連スキルを取得
  - keywords: [flutter, dart]
    suggest:
      core: [ai-development-guidelines]
      mobile-common: [mobile-ux, mobile-tdd]
      flutter: [flutter-development]
```

---

## スキル取得コマンド

### 単一スキル取得

**PowerShell**
```powershell
$skillPath = "core/skills/ai-development-guidelines"
$url = "https://raw.githubusercontent.com/t2k2pp/agent-registry/main/$skillPath/SKILL.md"
$dest = ".agent/skills/$(Split-Path $skillPath -Leaf)"
New-Item -ItemType Directory -Force -Path $dest
Invoke-WebRequest -Uri $url -OutFile "$dest/SKILL.md"
```

**Bash/Zsh**
```bash
skill_path="core/skills/ai-development-guidelines"
url="https://raw.githubusercontent.com/t2k2pp/agent-registry/main/$skill_path/SKILL.md"
dest=".agent/skills/$(basename $skill_path)"
mkdir -p "$dest"
curl -sL "$url" -o "$dest/SKILL.md"
```

---

## 推奨取得順序

| 優先度 | スキル | 理由 |
|-------|-------|------|
| 1 | ai-development-guidelines | AI開発の基本原則 |
| 2 | tech-stack-selector | フレームワーク未定時 |
| 3 | FW固有スキル | 選択されたFWに応じて |

---

## 取得後の確認

```
取得したスキル:
- core/ai-development-guidelines
- domains/mobile/common/mobile-ux
- domains/mobile/flutter/flutter-development

次のステップ:
各スキルの内容に従って開発を進めてください。
```
