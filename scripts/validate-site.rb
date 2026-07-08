#!/usr/bin/env ruby
# frozen_string_literal: true

# 构建前站点校验：Jekyll 不对"语义必填项缺失"报错（只渲染空值），
# 故用本脚本在 Pages workflow 构建前 fail-loud——任一违反即非零退出，阻断部署（SC-20/21/23）。
# 契约：sdlc/specs/features/aggregation-portal/{entities.md, contracts.md}。

require 'yaml'
require 'date'

ROOT = File.expand_path('..', __dir__)
errors = []

def load_yaml(path)
  YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
rescue StandardError => e
  abort("[validate-site] YAML 解析失败: #{path}: #{e.message}")
end

# ── SC-20：_config.yml 必填项（title 非空 + baseurl 键已定义） ──
config_path = File.join(ROOT, '_config.yml')
errors << "_config.yml 缺失" unless File.exist?(config_path)
if File.exist?(config_path)
  config = load_yaml(config_path) || {}
  errors << "_config.yml 缺必填项 title（或为空）" if config['title'].to_s.strip.empty?
  errors << "_config.yml 缺必填项 baseurl（键须定义，根门户可为空串）" unless config.key?('baseurl')
end

# ── SC-21：SourceCard 必填字段（key/title/summary/entry_url/kind 全 NOT NULL；kind 枚举） ──
sources_path = File.join(ROOT, '_data', 'sources.yml')
errors << "_data/sources.yml 缺失" unless File.exist?(sources_path)
if File.exist?(sources_path)
  cards = load_yaml(sources_path) || []
  errors << "_data/sources.yml 应为非空列表" unless cards.is_a?(Array) && !cards.empty?
  required = %w[key title summary entry_url kind]
  valid_kinds = %w[same-repo proxied]
  keys_seen = {}
  Array(cards).each_with_index do |card, i|
    unless card.is_a?(Hash)
      errors << "SourceCard[#{i}] 非法（应为对象）"
      next
    end
    required.each do |field|
      errors << "SourceCard[#{i}](#{card['key'] || '?'}) 缺必填字段 #{field}" if card[field].to_s.strip.empty?
    end
    unless valid_kinds.include?(card['kind'].to_s)
      errors << "SourceCard[#{i}](#{card['key'] || '?'}) kind 非法：#{card['kind'].inspect}（须 ∈ #{valid_kinds}）"
    end
    if card['key']
      errors << "SourceCard key 重复：#{card['key']}" if keys_seen[card['key']]
      keys_seen[card['key']] = true
    end
  end
end

# ── SC-23 / INV-01：经路径挂载的同仓子站，其 collection permalink 前缀 = 挂载路径 ──
# baseurl 错位（如 claude_blog permalink 不带 /claude-blog/ 前缀）→ CSS/内链前缀错位、子站 404。
# 前置到构建期校验（非零退出阻断部署），对应 ADR-004 baseurl 铁律。
if File.exist?(config_path)
  config ||= load_yaml(config_path) || {}
  # 挂载子站 = 必需 collection（缺失即子站不渲染，比前缀错位更严重 → 同样 fail-loud）。
  mounts = { 'claude_blog' => '/claude-blog/' }
  collections = config['collections'] || {}
  mounts.each do |coll, prefix|
    unless collections.key?(coll) && collections[coll].is_a?(Hash)
      errors << "缺必需挂载 collection `#{coll}`（子站 #{prefix} 将不渲染，INV-01/SC-23）"
      next
    end
    cfg = collections[coll]
    errors << "collection #{coll} 须 output: true（否则不生成子站页面，SC-23）" unless cfg['output'] == true
    permalink = cfg['permalink'].to_s
    if permalink.empty?
      errors << "collection #{coll} 缺 permalink（须以 #{prefix} 开头，INV-01/SC-23）"
    elsif !permalink.start_with?(prefix)
      errors << "collection #{coll} permalink 前缀错位：#{permalink.inspect}（须以 #{prefix} 开头，INV-01/SC-23）"
    end
  end
end

# ── SC-22（非致命）：同仓小源 digest 缺 published_at 排序键 → stderr 告警但不阻断 ──
# 最新流会跳过这些条目（portal-home.html where_exp 过滤），此处产出可识别告警关键词供构建日志诊断。
posts_dir = File.join(ROOT, 'sources', 'claude-blog', 'posts')
if Dir.exist?(posts_dir)
  Dir.glob(File.join(posts_dir, '**', '*.md')).sort.each do |md|
    front = File.read(md)[/\A---\s*\n(.*?)\n---\s*\n/m, 1]
    next unless front
    meta = begin
      YAML.safe_load(front, permitted_classes: [Date, Time]) || {}
    rescue StandardError
      next # front matter 解析问题不在本非致命扫描职责内
    end
    if meta['published_at'].to_s.strip.empty?
      warn "[validate-site][WARN] digest 缺 published_at 排序键，最新流将跳过：#{md.sub(ROOT + '/', '')}"
    end
  end
end

if errors.empty?
  puts '[validate-site] OK'
  exit 0
else
  warn '[validate-site] 校验失败，阻断构建/部署：'
  errors.each { |e| warn "  - #{e}" }
  exit 1
end
