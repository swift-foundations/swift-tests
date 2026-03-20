# Tests Insights

<!--
---
title: Tests Insights
version: 1.0.0
last_updated: 2026-03-20
applies_to: [swift-tests]
normative: false
---
-->

Design decisions, implementation patterns, and lessons learned specific to this package.

## Overview

This document captures insights that emerged during development of swift-tests.
These are not API requirements — they are recorded decisions and patterns that inform
future work on this package.

**Document type**: Non-normative (recorded decisions, not requirements).

**Consolidation source**: Reflection entries tagged with `[package: swift-tests]`.

---

## #filePath to File.Path Conversion Hack

**Date**: 2026-03-20

**Context**: 6 occurrences of `File.Path(stringLiteral: #filePath)` exist in swift-tests. This is a workaround for converting the `#filePath` String to `File.Path` without using the throwing `init(_:)` (which conflicts with `ExpressibleByStringLiteral` per [IMPL-037]).

Needs a principled solution — either `Path.init(unchecked:)` for known-valid strings or a dedicated `#filePath`-aware init. The string interpolation pattern (`"\(#filePath)"`) is technically correct but semantically wrong — `#filePath` is already a valid path, not arbitrary user input.

**Applies to**: Test infrastructure files that locate test fixtures relative to source.
