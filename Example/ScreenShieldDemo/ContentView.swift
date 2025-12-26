//
//  ContentView.swift
//  ScreenShieldDemo
//
//  Created by Chandan Kumar Dash on 26/12/2025.
//
//  Demonstrates ScreenShield usage with SwiftUI.
//

import SwiftUI
import ScreenShield

struct ContentView: View {
    @State private var isProtectionEnabled = true
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Toggle
                    protectionToggle
                    
                    // Comparison Demo
                    comparisonSection
                    
                    // Credit Card Demo
                    creditCardSection
                    
                    // Instructions
                    instructionsSection
                }
                .padding()
            }
            .navigationTitle("ScreenShield Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAlert = true }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .alert("About ScreenShield", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This demo shows how ScreenShield protects sensitive content from screenshots and screen recordings using the isSecureTextEntry technique.")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Screenshot Protection Demo")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try taking a screenshot to see the protection in action")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Protection Toggle
    
    private var protectionToggle: some View {
        HStack {
            Image(systemName: isProtectionEnabled ? "lock.fill" : "lock.open.fill")
                .foregroundColor(isProtectionEnabled ? .green : .red)
            
            Toggle("Protection Enabled", isOn: $isProtectionEnabled)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Comparison Section
    
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparison")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Unprotected
                VStack(spacing: 8) {
                    Text("Unprotected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack {
                        Image(systemName: "eye")
                            .font(.title)
                        Text("Visible")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Protected
                VStack(spacing: 8) {
                    Text("Protected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScreenShieldView(isProtected: isProtectionEnabled) {
                        VStack {
                            Image(systemName: "eye.slash")
                                .font(.title)
                            Text("Hidden")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Credit Card Section
    
    private var creditCardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sensitive Data Example")
                .font(.headline)
            
            ScreenShieldView(isProtected: isProtectionEnabled) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("VISA")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "wave.3.right")
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("4242 4242 4242 4242")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(.white)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("CARDHOLDER")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("JOHN DOE")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("EXPIRES")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("12/28")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .trailing) {
                            Text("CVV")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("***")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.leading, 16)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Test")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                instructionRow(number: 1, text: "Take a screenshot (Power + Volume Up)")
                instructionRow(number: 2, text: "Check the screenshot in Photos")
                instructionRow(number: 3, text: "Protected content should appear blank")
                instructionRow(number: 4, text: "Toggle protection off to compare")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
