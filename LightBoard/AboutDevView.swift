//
//  AboutDevView.swift
//  LightBoard
//
//  Created by Tejas Kathuria on 25/11/25.
//

import SwiftUI

struct AboutDevView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                
                Text("About Developer")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.top, 20)
            
            Divider()
            
            // for dev info
            VStack(spacing: 12) {
                Text("This app is developed by")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("Tejas Kathuria")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            // Social links
            VStack(spacing: 12) {
              
                Link(destination: URL(string: "https://github.com/tejaskathuria")!) {
                    HStack {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.title3)
                        Text("GitHub")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
               
                Link(destination: URL(string: "https://x.com/tejaskathuria_")!) {
                    HStack {
                        Image(systemName: "bird.fill")
                            .font(.title3)
                        Text("Twitter")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Footer
            Text("LightBoard v1.0")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
        }
        .frame(width: 300, height: 350)
        .padding()
    }
}

#Preview {
    AboutDevView()
}
