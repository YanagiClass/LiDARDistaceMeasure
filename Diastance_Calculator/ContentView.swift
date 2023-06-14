// ContentView.swift 파일
// Diastance_Calculator 프로젝트를 위한 코드
// 유용상이 2023년 4월 4일에 작성

import SwiftUI
import ARKit

// ContentView 구조체를 정의하고 View 프로토콜을 구현
struct ContentView: View {
    // 뷰의 상태 속성
    @State private var isMeasuring = false
    @State private var start: simd_float3?
    @State private var end: simd_float3?
    
    // SwiftUI의 body 속성을 정의하여 사용자 인터페이스를 렌더링
    var body: some View {
        ZStack {
            // 거리 측정 뷰를 추가
            DistanceMeasurementView(isMeasuring: $isMeasuring, start: $start, end: $end)
            
            // VStack을 이용하여 텍스트 및 버튼을 정렬
            VStack {
                Spacer()
                
                // 측정된 거리를 표시하는 텍스트
                Text(distanceText)
                    .font(.system(size: 24, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                
                // 거리 측정을 시작하거나 재설정하는 버튼
                Button(action: {
                    isMeasuring.toggle()
                    if !isMeasuring {
                        start = nil
                        end = nil
                    }
                }) {
                    Text(isMeasuring ? "Reset" : "Start Measuring")
                        .font(.system(size: 24, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(isMeasuring ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
    
    // 거리 텍스트를 계산하고 문자열로 반환하는 private 변수
    private var distanceText: String {
        guard let start = start, let end = end else {
            return "Distance: --"
        }
        
        // 시작점과 끝점 사이의 거리를 계산
        let distance = simd_distance(start, end)
        let meters = Measurement(value: Double(distance), unit: UnitLength.meters)

        // 거리를 형식화하여 문자열로 변환
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.unitStyle = .medium
        measurementFormatter.numberFormatter.maximumFractionDigits = 2

        let formattedDistance = measurementFormatter.string(from: meters)
        
        return "Distance: \(formattedDistance)"
    }
}

// AR을 사용하여 거리를 측정하는 뷰를 구현하는 구조체
struct DistanceMeasurementView: UIViewRepresentable {
    // 바인딩 속성
    @Binding var isMeasuring: Bool
    @Binding var start: simd_float3?
    @Binding var end: simd_float3?
    
    // 코디네이터를 생성하는 함수
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // ARSCNView를 생성하는 함수
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.session.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        
        // AR 세션을 구성하고 실행
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        arView.session.run(config)
        
        return arView
    }
    
    // 뷰를 업데이트하는 함수 (여기서는 별도의 작업이 없음)
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    // AR 세션 델리게이트를 구현하는 Coordinator 클래스
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: DistanceMeasurementView
        
        init(_ parent: DistanceMeasurementView) {
            self.parent = parent
        }
        
        // AR 세션이 업데이트되면 호출되는 메소드
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // isMeasuring이 참이고, 히트 테스트 결과가 있는 경우에만 작업 수행
            guard parent.isMeasuring, let hitTest = frame.hitTest(CGPoint(x: 0.5, y: 0.5), types: .featurePoint).first else {
                return
            }
            
            // 히트 테스트 결과의 위치를 가져옴
            let position = simd_make_float3(hitTest.worldTransform.columns.3)
            
            // 시작점이 없으면 설정, 있으면 끝점을 업데이트
            if parent.start == nil {
                parent.start = position
            } else {
                parent.end = position
            }
        }
    }
}

// 앱의 메인 구조체
//@main
struct DistanceMeasurementApp: App {
    // 앱의 윈도우 그룹을 정의
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

