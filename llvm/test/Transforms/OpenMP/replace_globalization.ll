; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --check-attributes --check-globals --include-generated-funcs
; RUN: opt -S -passes='openmp-opt' < %s | FileCheck %s
; RUN: opt -passes=openmp-opt -pass-remarks=openmp-opt -disable-output < %s 2>&1 | FileCheck %s -check-prefix=CHECK-REMARKS
; RUN: opt -passes=openmp-opt -pass-remarks=openmp-opt -pass-remarks-missed=openmp-opt -disable-output -openmp-opt-shared-limit=4 < %s 2>&1 | FileCheck %s -check-prefix=CHECK-LIMIT
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64"

; UTC_ARGS: --disable
; CHECK-REMARKS: remark: replace_globalization.c:5:7: Replaced globalized variable with 16 bytes of shared memory
; CHECK-REMARKS: remark: replace_globalization.c:5:14: Replaced globalized variable with 4 bytes of shared memory
; CHECK-REMARKS-NOT: 6 bytes
; CHECK-LIMIT: remark: replace_globalization.c:5:14: Replaced globalized variable with 4 bytes of shared memory
; CHECK-LIMIT: remark: replace_globalization.c:5:7: Found thread data sharing on the GPU. Expect degraded performance due to data globalization
; UTC_ARGS: --enable

%struct.ident_t = type { i32, i32, i32, i32, ptr }
%struct.KernelEnvironmentTy = type { %struct.ConfigurationEnvironmentTy, ptr, ptr }
%struct.ConfigurationEnvironmentTy = type { i8, i8, i8, i32, i32, i32, i32, i32, i32 }

@S = external local_unnamed_addr global ptr
@0 = private unnamed_addr constant [113 x i8] c";llvm/test/Transforms/OpenMP/custom_state_machines_remarks.c;__omp_offloading_2a_d80d3d_test_fallback_l11;11;1;;\00", align 1
@1 = private unnamed_addr constant %struct.ident_t { i32 0, i32 2, i32 0, i32 0, ptr @0 }, align 8
@foo_kernel_environment = local_unnamed_addr constant %struct.KernelEnvironmentTy { %struct.ConfigurationEnvironmentTy { i8 0, i8 0, i8 1, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0 }, ptr @1, ptr null }
@bar_kernel_environment = local_unnamed_addr constant %struct.KernelEnvironmentTy { %struct.ConfigurationEnvironmentTy { i8 0, i8 0, i8 1, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0 }, ptr @1, ptr null }
@baz_kernel_environment = local_unnamed_addr constant %struct.KernelEnvironmentTy { %struct.ConfigurationEnvironmentTy { i8 0, i8 0, i8 2, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0 }, ptr @1, ptr null }


define dso_local ptx_kernel void @foo(ptr %dyn) "kernel" {
entry:
  %c = call i32 @__kmpc_target_init(ptr @foo_kernel_environment, ptr %dyn)
  %x = call align 4 ptr @__kmpc_alloc_shared(i64 4)
  call void @unknown_no_openmp()
  call void @use(ptr %x)
  call void @__kmpc_free_shared(ptr %x, i64 4)
  call void @__kmpc_target_deinit()
  ret void
}

define ptx_kernel void @bar(ptr %dyn) "kernel" {
  %c = call i32 @__kmpc_target_init(ptr @bar_kernel_environment, ptr %dyn)
  call void @unknown_no_openmp()
  %cmp = icmp eq i32 %c, -1
  br i1 %cmp, label %master1, label %exit
master1:
  %x = call align 4 ptr @__kmpc_alloc_shared(i64 16), !dbg !11
  call void @use(ptr %x)
  call void @__kmpc_free_shared(ptr %x, i64 16)
  br label %next
next:
  call void @unknown_no_openmp()
  %b0 = icmp eq i32 %c, -1
  br i1 %b0, label %master2, label %exit
master2:
  %y = call align 4 ptr @__kmpc_alloc_shared(i64 4), !dbg !12
  call void @use(ptr %y)
  call void @__kmpc_free_shared(ptr %y, i64 4)
  br label %exit
exit:
  call void @__kmpc_target_deinit()
  ret void
}

define ptx_kernel void @baz_spmd(ptr %dyn) "kernel" {
  %c = call i32 @__kmpc_target_init(ptr @baz_kernel_environment, ptr %dyn)
  call void @unknown_no_openmp()
  %c0 = icmp eq i32 %c, -1
  br i1 %c0, label %master3, label %exit
master3:
  %z = call align 4 ptr @__kmpc_alloc_shared(i64 24), !dbg !12
  call void @use(ptr %z)
  call void @__kmpc_free_shared(ptr %z, i64 24)
  br label %exit
exit:
  call void @__kmpc_target_deinit()
  ret void
}

define void @use(ptr %x) {
entry:
  store ptr %x, ptr @S
  ret void
}

@offset =global i32 undef
@stack = internal addrspace(3) global [1024 x i8] undef
define private ptr @__kmpc_alloc_shared(i64) {
  %ac = addrspacecast ptr addrspace(3) @stack to ptr
  %l = load i32, ptr @offset
  %gep = getelementptr i8, ptr %ac, i32 %l
  ret ptr %gep
}

declare void @__kmpc_free_shared(ptr, i64)

declare i32 @llvm.nvvm.read.ptx.sreg.tid.x()

declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x()

declare i32 @llvm.nvvm.read.ptx.sreg.warpsize()

; Make it a weak definition so we will apply custom state machine rewriting but can't use the body in the reasoning.
define weak i32 @__kmpc_target_init(ptr, ptr) {
  ret i32 0
}

declare void @__kmpc_target_deinit()

declare void @unknown_no_openmp() "llvm.assume"="omp_no_openmp"

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4, !5, !6}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 12.0.0", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "replace_globalization.c", directory: "/tmp/replace_globalization.c")
!2 = !{}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"openmp", i32 50}
!6 = !{i32 7, !"openmp-device", i32 50}
!9 = distinct !DISubprogram(name: "bar", scope: !1, file: !1, line: 1, type: !10, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !2)
!10 = !DISubroutineType(types: !2)
!11 = !DILocation(line: 5, column: 7, scope: !9)
!12 = !DILocation(line: 5, column: 14, scope: !9)
;.
; CHECK: @S = external local_unnamed_addr global ptr
; CHECK: @[[GLOB0:[0-9]+]] = private unnamed_addr constant [113 x i8] c"
; CHECK: @[[GLOB1:[0-9]+]] = private unnamed_addr constant %struct.ident_t { i32 0, i32 2, i32 0, i32 0, ptr @[[GLOB0]] }, align 8
; CHECK: @foo_kernel_environment = local_unnamed_addr constant %struct.KernelEnvironmentTy { %struct.ConfigurationEnvironmentTy { i8 0, i8 0, i8 1, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0 }, ptr @[[GLOB1]], ptr null }
; CHECK: @bar_kernel_environment = local_unnamed_addr constant %struct.KernelEnvironmentTy { %struct.ConfigurationEnvironmentTy { i8 0, i8 0, i8 1, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0 }, ptr @[[GLOB1]], ptr null }
; CHECK: @baz_kernel_environment = local_unnamed_addr constant %struct.KernelEnvironmentTy { %struct.ConfigurationEnvironmentTy { i8 0, i8 0, i8 2, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0 }, ptr @[[GLOB1]], ptr null }
; CHECK: @offset = global i32 undef
; CHECK: @stack = internal addrspace(3) global [1024 x i8] undef
; CHECK: @x_shared = internal addrspace(3) global [16 x i8] poison, align 4
; CHECK: @y_shared = internal addrspace(3) global [4 x i8] poison, align 4
;.
; CHECK-LABEL: define {{[^@]+}}@foo
; CHECK-SAME: (ptr [[DYN:%.*]]) #[[ATTR0:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[C:%.*]] = call i32 @__kmpc_target_init(ptr @foo_kernel_environment, ptr [[DYN]])
; CHECK-NEXT:    [[X:%.*]] = call align 4 ptr @__kmpc_alloc_shared(i64 4) #[[ATTR6:[0-9]+]]
; CHECK-NEXT:    call void @unknown_no_openmp() #[[ATTR5:[0-9]+]]
; CHECK-NEXT:    call void @use.internalized(ptr nofree [[X]]) #[[ATTR7:[0-9]+]]
; CHECK-NEXT:    call void @__kmpc_free_shared(ptr [[X]], i64 4) #[[ATTR8:[0-9]+]]
; CHECK-NEXT:    call void @__kmpc_target_deinit()
; CHECK-NEXT:    ret void
;
;
; CHECK-LABEL: define {{[^@]+}}@bar
; CHECK-SAME: (ptr [[DYN:%.*]]) #[[ATTR0]] {
; CHECK-NEXT:    [[C:%.*]] = call i32 @__kmpc_target_init(ptr @bar_kernel_environment, ptr [[DYN]])
; CHECK-NEXT:    call void @unknown_no_openmp() #[[ATTR5]]
; CHECK-NEXT:    [[CMP:%.*]] = icmp eq i32 [[C]], -1
; CHECK-NEXT:    br i1 [[CMP]], label [[MASTER1:%.*]], label [[EXIT:%.*]]
; CHECK:       master1:
; CHECK-NEXT:    call void @use.internalized(ptr nofree addrspacecast (ptr addrspace(3) @x_shared to ptr)) #[[ATTR7]]
; CHECK-NEXT:    br label [[NEXT:%.*]]
; CHECK:       next:
; CHECK-NEXT:    call void @unknown_no_openmp() #[[ATTR5]]
; CHECK-NEXT:    [[B0:%.*]] = icmp eq i32 [[C]], -1
; CHECK-NEXT:    br i1 [[B0]], label [[MASTER2:%.*]], label [[EXIT]]
; CHECK:       master2:
; CHECK-NEXT:    call void @use.internalized(ptr nofree addrspacecast (ptr addrspace(3) @y_shared to ptr)) #[[ATTR7]]
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    call void @__kmpc_target_deinit()
; CHECK-NEXT:    ret void
;
;
; CHECK-LABEL: define {{[^@]+}}@baz_spmd
; CHECK-SAME: (ptr [[DYN:%.*]]) #[[ATTR0]] {
; CHECK-NEXT:    [[C:%.*]] = call i32 @__kmpc_target_init(ptr @baz_kernel_environment, ptr [[DYN]])
; CHECK-NEXT:    call void @unknown_no_openmp() #[[ATTR5]]
; CHECK-NEXT:    [[C0:%.*]] = icmp eq i32 [[C]], -1
; CHECK-NEXT:    br i1 [[C0]], label [[MASTER3:%.*]], label [[EXIT:%.*]]
; CHECK:       master3:
; CHECK-NEXT:    [[Z:%.*]] = call align 4 ptr @__kmpc_alloc_shared(i64 24) #[[ATTR6]], !dbg [[DBG7:![0-9]+]]
; CHECK-NEXT:    call void @use.internalized(ptr nofree [[Z]]) #[[ATTR7]]
; CHECK-NEXT:    call void @__kmpc_free_shared(ptr [[Z]], i64 24) #[[ATTR8]]
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    call void @__kmpc_target_deinit()
; CHECK-NEXT:    ret void
;
;
; CHECK: Function Attrs: nofree norecurse nosync nounwind memory(write)
; CHECK-LABEL: define {{[^@]+}}@use.internalized
; CHECK-SAME: (ptr nofree [[X:%.*]]) #[[ATTR1:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    store ptr [[X]], ptr @S, align 8
; CHECK-NEXT:    ret void
;
;
; CHECK-LABEL: define {{[^@]+}}@use
; CHECK-SAME: (ptr [[X:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    store ptr [[X]], ptr @S, align 8
; CHECK-NEXT:    ret void
;
;
; CHECK: Function Attrs: nosync nounwind allocsize(0) memory(read)
; CHECK-LABEL: define {{[^@]+}}@__kmpc_alloc_shared
; CHECK-SAME: (i64 [[TMP0:%.*]]) #[[ATTR2:[0-9]+]] {
; CHECK-NEXT:    [[L:%.*]] = load i32, ptr @offset, align 4
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr i8, ptr addrspacecast (ptr addrspace(3) @stack to ptr), i32 [[L]]
; CHECK-NEXT:    ret ptr [[GEP]]
;
;
; CHECK-LABEL: define {{[^@]+}}@__kmpc_target_init
; CHECK-SAME: (ptr [[TMP0:%.*]], ptr [[TMP1:%.*]]) {
; CHECK-NEXT:    ret i32 0
;
;.
; CHECK: attributes #[[ATTR0]] = { "kernel" }
; CHECK: attributes #[[ATTR1]] = { nofree norecurse nosync nounwind memory(write) }
; CHECK: attributes #[[ATTR2]] = { nosync nounwind allocsize(0) memory(read) }
; CHECK: attributes #[[ATTR3:[0-9]+]] = { nosync nounwind }
; CHECK: attributes #[[ATTR4:[0-9]+]] = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
; CHECK: attributes #[[ATTR5]] = { "llvm.assume"="omp_no_openmp" }
; CHECK: attributes #[[ATTR6]] = { nounwind memory(read) }
; CHECK: attributes #[[ATTR7]] = { nosync nounwind memory(write) }
; CHECK: attributes #[[ATTR8]] = { nounwind }
;.
; CHECK: [[META0:![0-9]+]] = distinct !DICompileUnit(language: DW_LANG_C99, file: [[META1:![0-9]+]], producer: "{{.*}}clang version {{.*}}", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: [[META2:![0-9]+]], splitDebugInlining: false, nameTableKind: None)
; CHECK: [[META1]] = !DIFile(filename: "replace_globalization.c", directory: {{.*}})
; CHECK: [[META2]] = !{}
; CHECK: [[META3:![0-9]+]] = !{i32 2, !"Debug Info Version", i32 3}
; CHECK: [[META4:![0-9]+]] = !{i32 1, !"wchar_size", i32 4}
; CHECK: [[META5:![0-9]+]] = !{i32 7, !"openmp", i32 50}
; CHECK: [[META6:![0-9]+]] = !{i32 7, !"openmp-device", i32 50}
; CHECK: [[DBG7]] = !DILocation(line: 5, column: 14, scope: [[META8:![0-9]+]])
; CHECK: [[META8]] = distinct !DISubprogram(name: "bar", scope: [[META1]], file: [[META1]], line: 1, type: [[META9:![0-9]+]], scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: [[META0]], retainedNodes: [[META2]])
; CHECK: [[META9]] = !DISubroutineType(types: [[META2]])
;.
;; NOTE: These prefixes are unused and the list is autogenerated. Do not add tests below this line:
; CHECK-LIMIT: {{.*}}
; CHECK-REMARKS: {{.*}}
