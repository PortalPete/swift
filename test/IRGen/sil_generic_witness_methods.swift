// RUN: %target-swift-frontend -primary-file %s -emit-ir -disable-objc-attr-requires-foundation-module | FileCheck %s

// REQUIRES: CPU=x86_64

// FIXME: These should be SIL tests, but we can't parse generic types in SIL
// yet.

protocol P {
  func concrete_method()
  static func concrete_static_method()
  func generic_method<Z>(x: Z)
}

struct S {}

// CHECK-LABEL: define hidden void @_TF27sil_generic_witness_methods12call_methods{{.*}}(%swift.opaque* noalias nocapture, %swift.opaque* noalias nocapture, %swift.type* %T, i8** %T.P, %swift.type* %U)
func call_methods<T: P, U>(x: T, y: S, z: U) {
  // CHECK: [[STATIC_METHOD_ADDR:%.*]] = getelementptr inbounds i8*, i8** %T.P, i32 1
  // CHECK: [[STATIC_METHOD_PTR:%.*]] = load i8*, i8** [[STATIC_METHOD_ADDR]], align 8
  // CHECK: [[STATIC_METHOD:%.*]] = bitcast i8* [[STATIC_METHOD_PTR]] to void (%swift.type*, %swift.type*)*
  // CHECK: call void [[STATIC_METHOD]](%swift.type* %T, %swift.type* %T)
  T.concrete_static_method()

  // CHECK: [[CONCRETE_METHOD_PTR:%.*]] = load i8*, i8** %T.P, align 8
  // CHECK: [[CONCRETE_METHOD:%.*]] = bitcast i8* [[CONCRETE_METHOD_PTR]] to void (%swift.opaque*, %swift.type*)*
  // CHECK: call void [[CONCRETE_METHOD]](%swift.opaque* noalias nocapture {{%.*}}, %swift.type* %T)
  x.concrete_method()
  // CHECK: [[GENERIC_METHOD_ADDR:%.*]] = getelementptr inbounds i8*, i8** %T.P, i32 2
  // CHECK: [[GENERIC_METHOD_PTR:%.*]] = load i8*, i8** [[GENERIC_METHOD_ADDR]], align 8
  // CHECK: [[GENERIC_METHOD:%.*]] = bitcast i8* [[GENERIC_METHOD_PTR]] to void (%swift.opaque*, %swift.type*, %swift.opaque*, %swift.type*)*
  // CHECK: call void [[GENERIC_METHOD]](%swift.opaque* noalias nocapture {{.*}}, %swift.type* getelementptr inbounds ({{.*}} @_TMdV27sil_generic_witness_methods1S {{.*}}), %swift.opaque* {{.*}}, %swift.type* %T)
  x.generic_method(y)
  // CHECK: [[GENERIC_METHOD_ADDR:%.*]] = getelementptr inbounds i8*, i8** %T.P, i32 2
  // CHECK: [[GENERIC_METHOD_PTR:%.*]] = load i8*, i8** [[GENERIC_METHOD_ADDR]], align 8
  // CHECK: [[GENERIC_METHOD:%.*]] = bitcast i8* [[GENERIC_METHOD_PTR]] to void (%swift.opaque*, %swift.type*, %swift.opaque*, %swift.type*)*
  // CHECK: call void [[GENERIC_METHOD]](%swift.opaque* noalias nocapture {{.*}}, %swift.type* %U, %swift.opaque* {{.*}}, %swift.type* %T)
  x.generic_method(z)
}

// CHECK-LABEL: define hidden void @_TF27sil_generic_witness_methods24call_existential_methods{{.*}}(%P27sil_generic_witness_methods1P_* noalias nocapture dereferenceable({{.*}}))
func call_existential_methods(x: P, var y: S) {
  // CHECK: [[METADATA_ADDR:%.*]] = getelementptr inbounds %P27sil_generic_witness_methods1P_, %P27sil_generic_witness_methods1P_* [[X:%0]], i32 0, i32 1
  // CHECK: [[METADATA:%.*]] = load %swift.type*, %swift.type** [[METADATA_ADDR]], align 8
  // CHECK: [[WTABLE_ADDR:%.*]] = getelementptr inbounds %P27sil_generic_witness_methods1P_, %P27sil_generic_witness_methods1P_* [[X]], i32 0, i32 2
  // CHECK: [[WTABLE:%.*]] = load i8**, i8*** [[WTABLE_ADDR]], align 8
  // CHECK: [[CONCRETE_METHOD_PTR:%.*]] = load i8*, i8** [[WTABLE]], align 8
  // CHECK: [[CONCRETE_METHOD:%.*]] = bitcast i8* [[CONCRETE_METHOD_PTR]] to void (%swift.opaque*, %swift.type*)*
  // CHECK: call void [[CONCRETE_METHOD]](%swift.opaque* noalias nocapture {{%.*}}, %swift.type* [[METADATA]])
  x.concrete_method()

  // CHECK: [[METADATA_ADDR:%.*]] = getelementptr inbounds %P27sil_generic_witness_methods1P_, %P27sil_generic_witness_methods1P_* [[X]], i32 0, i32 1
  // CHECK: [[METADATA:%.*]] = load %swift.type*, %swift.type** [[METADATA_ADDR]], align 8
  // CHECK: [[WTABLE_ADDR:%.*]] = getelementptr inbounds %P27sil_generic_witness_methods1P_, %P27sil_generic_witness_methods1P_* [[X:%.*]], i32 0, i32 2
  // CHECK: [[WTABLE:%.*]] = load i8**, i8*** [[WTABLE_ADDR]], align 8
  // CHECK: [[GENERIC_METHOD_ADDR:%.*]] = getelementptr inbounds i8*, i8** [[WTABLE]], i32 2
  // CHECK: [[GENERIC_METHOD_PTR:%.*]] = load i8*, i8** [[GENERIC_METHOD_ADDR]], align 8
  // CHECK: [[GENERIC_METHOD:%.*]] = bitcast i8* [[GENERIC_METHOD_PTR]] to void (%swift.opaque*, %swift.type*, %swift.opaque*, %swift.type*)*
  // CHECK: call void [[GENERIC_METHOD]](%swift.opaque* noalias nocapture {{.*}}, %swift.type* getelementptr inbounds ({{.*}} @_TMdV27sil_generic_witness_methods1S {{.*}}), %swift.opaque* noalias nocapture {{%.*}}, %swift.type* [[METADATA]])
  x.generic_method(y)
}

@objc protocol ObjC {
  func method()
}

// CHECK-LABEL: define hidden void @_TF27sil_generic_witness_methods16call_objc_method{{.*}}(%objc_object*, %swift.type* %T) {{.*}} {
// CHECK:         [[SEL:%.*]] = load i8*, i8** @"\01L_selector(method)", align 8
// CHECK:         [[CAST:%.*]] = bitcast %objc_object* %0 to [[SELFTYPE:%?.*]]*
// CHECK:         call void bitcast (void ()* @objc_msgSend to void ([[SELFTYPE]]*, i8*)*)([[SELFTYPE]]* [[CAST]], i8* [[SEL]])
func call_objc_method<T: ObjC>(x: T) {
  x.method()
}

// CHECK-LABEL: define hidden void @_TF27sil_generic_witness_methods21call_call_objc_method{{.*}}(%objc_object*, %swift.type* %T) {{.*}} {
// CHECK:         call void @_TF27sil_generic_witness_methods16call_objc_method{{.*}}(%objc_object* %0, %swift.type* %T)
func call_call_objc_method<T: ObjC>(x: T) {
  call_objc_method(x)
}

// CHECK-LABEL: define hidden void @_TF27sil_generic_witness_methods28call_objc_existential_method{{.*}}(%objc_object*) {{.*}} {
// CHECK:         [[SEL:%.*]] = load i8*, i8** @"\01L_selector(method)", align 8
// CHECK:         [[CAST:%.*]] = bitcast %objc_object* %0 to [[SELFTYPE:%?.*]]*
// CHECK:         call void bitcast (void ()* @objc_msgSend to void ([[SELFTYPE]]*, i8*)*)([[SELFTYPE]]* [[CAST]], i8* [[SEL]])
func call_objc_existential_method(x: ObjC) {
  x.method()
}
