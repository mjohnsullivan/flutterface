// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show Point, Rectangle;
import 'dart:ui' show Offset, Rect;

Rect rectangleToRect(Rectangle rectangle) => Rect.fromLTRB(
    rectangle.left.toDouble(),
    rectangle.top.toDouble(),
    rectangle.right.toDouble(),
    rectangle.bottom.toDouble());

Offset pointToOffset(Point point) =>
    Offset(point.x.toDouble(), point.y.toDouble());
