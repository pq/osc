// Copyright (c) 2021, Google LLC. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('check for copyright headers', () {
    test('... in lib', () async {
      await validate('lib');
    });
  });
}

Future validate(String dir) async {
  var violations = <String>[];
  await for (FileSystemEntity entity
      in Directory(dir).list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var file = await entity.open();
      var bytes = await file.read(40);
      var header = String.fromCharCodes(bytes);
      if (!header.startsWith(
          RegExp('// Copyright \\(c\\) 20[0-9][0-9], Google LLC'))) {
        violations.add(entity.path);
      }
    }
  }
  expect(violations, isEmpty, reason: '''Files missing copyright headers.
See CONTRIBUTING.md for format details.''');
}
