// This file is part of Cursor - a mod that _runs_.
// Copyright (C) 2025 ah-OOG-ah
//
// Cursor is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Cursor is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    const SIZE = 33;
    const YSZE = 5;
    var noise: [SIZE * YSZE * SIZE]f64 = undefined;

    root.lazy_populateNoiseArray(@ptrCast(&noise),
        0.0, 0.0, 0.0,
        SIZE, YSZE, SIZE,
        0.1, 0.1, 0.1,
        1.0, 1337);
}
