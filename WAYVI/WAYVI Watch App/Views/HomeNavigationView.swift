//
//  HomeNavigationView.swift
//  WAYVI
//
//  Created by 이지희 on 5/18/25.
//

import SwiftUI
import WatchKit
import AVFoundation

struct HomeNavigationView: View {
    @StateObject private var viewModel = NavigationViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var speechManager = SpeechManager()
    @State private var showResultView = false
    @State private var showTransitView = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView("길을 찾는 중...")
                } else {
                    Button(action: {
                        presentSpeechInput()
                    }) {
                        Label("길 안내 시작", systemImage: "location.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: {
                        showTransitView = true
                    }) {
                        Label("대중교통 안내", systemImage: "bus")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationDestination(isPresented: $showResultView) {
                if let result = viewModel.routeResult {
                    NavigationResultView(result: result)
                } else {
                    Text("경로 정보를 불러오지 못했습니다.")
                }
            }
            .navigationDestination(isPresented: $showTransitView) {
                TransitSelectionView()
            }
            .onChange(of: viewModel.routeResult, initial: false) { oldValue, newValue in
                if newValue != nil {
                    showResultView = true
                }
            }
        }
    }

    private func presentSpeechInput() {
        speechManager.speak("상단의 버튼을 눌러 목적지를 말씀해주세요.")
        
        WKExtension.shared().visibleInterfaceController?.presentTextInputController(
            withSuggestions: ["동국대학교", "충무로역", "동대입구역"],
            allowedInputMode: .plain
        ) { results in
            if let destination = results?.first as? String,
               let location = locationManager.currentLocation {
                viewModel.searchRoute(currentLocation: location, destination: destination)
            }
        }
    }
    
    // MARK: - 위치 기반 대중교통 안내
    private func announceNearbyTransit() {
        guard let location = locationManager.currentLocation else {
            speechManager.speak("현재 위치를 확인할 수 없습니다.")
            return
        }

        let service = TransitSearchService()
        let group = DispatchGroup()

        var subwayResult: POIResult?
        var busResult: POIResult?

        group.enter()
        service.searchNearbyPOI(keyword: "지하철역", coordinate: location) { result in
            subwayResult = result
            group.leave()
        }

        group.enter()
        service.searchNearbyPOI(keyword: "버스정류장", coordinate: location) { result in
            busResult = result
            group.leave()
        }

        group.notify(queue: .main) {
            if let subway = subwayResult {
                speechManager.speak("근처 \(subway.distance)m 안에 \(subway.name)이 있습니다.")
            } else {
                speechManager.speak("근처 지하철역 정보를 찾을 수 없습니다.")
            }

            if let bus = busResult {
                speechManager.speak("근처 \(bus.distance)m 안에 \(bus.name) 정류장이 있습니다.")
            } else {
                speechManager.speak("근처 버스 정류장 정보를 찾을 수 없습니다.")
            }
        }
    }
}
