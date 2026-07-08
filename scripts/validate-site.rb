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

if errors.empty?
  puts '[validate-site] OK'
  exit 0
else
  warn '[validate-site] 校验失败，阻断构建/部署：'
  errors.each { |e| warn "  - #{e}" }
  exit 1
end
