import SwiftUI
import MonorailSwift

struct ContentView: View {
    @State private var logs: [String] = []
    @State private var isMonitoring = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("MonorailSwift SPM Demo")
                    .font(.headline)

                Toggle("Enable Network Logger", isOn: $isMonitoring)
                    .padding(.horizontal)
                    .onChange(of: isMonitoring) { newValue in
                        if newValue {
                            Monorail.enableLogger()
                            logs.append("Logger enabled")
                        } else {
                            logs.append("Logger disabled")
                        }
                    }

                Button("Make Sample Request") {
                    makeSampleRequest()
                }
                .buttonStyle(.borderedProminent)

              List(Array(logs.enumerated()), id: \.offset) { index, log in
                    Text(log)
                        .font(.caption)
                }
            }
            .navigationTitle("SPM Example")
        }
    }

    private func makeSampleRequest() {
        guard let url = URL(string: "https://httpbin.org/get") else { return }
        logs.append("Requesting \(url)...")

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    logs.append("Response: \(httpResponse.statusCode)")
                } else if let error = error {
                    logs.append("Error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}
