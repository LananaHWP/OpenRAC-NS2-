// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2026 the OpenRAC contributors
// OpenRAC on Switch 2: runtime/crash.cpp's interface (openrac/memory.h) without signals. Horizon delivers no SIGSEGV to a program,
// so the fault reports, OPENRAC_GUARD and OPENRAC_SOFT_FAULTS do not exist here; a terminate is logged before the program ends.
#include <cstdlib>
#include <exception>

#include "common/log.h"
#include "openrac/memory.h"

namespace openrac::runtime {
namespace {

[[noreturn]] void on_terminate() {
    log::fatal("std::terminate: an uncaught exception ended the program");
    std::abort();
}

}  // namespace

void install_crash_handler() {
    std::set_terminate(on_terminate);
}

void add_own_library(const void*) {}
void remove_own_library(const void*) {}
void guard_writes(gaddr, std::uint32_t, std::uint32_t) {}
void rearm_soft_faults() {}
const SoftFault* soft_fault_at(unsigned) {
    return nullptr;
}

}  // namespace openrac::runtime
