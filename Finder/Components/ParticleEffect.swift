import SwiftUI

// MARK: - Particle Types
enum ParticleType {
    case ember      // Горящие угольки
    case spark      // Искры
    case ash        // Пепел
    case flame      // Огненные частицы
    case smoke      // Дым
    case glow       // Свечение
    case fragment   // Фрагменты UI
    case dust       // Пыль
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
    var velocity: CGPoint
    var color: Color
    var type: ParticleType
    var lifetime: Double
    var maxLifetime: Double
    var angularVelocity: Double
    var drag: CGFloat
    var gravity: CGFloat
}

// MARK: - Advanced Particle System
class ParticleSystem: ObservableObject {
    @Published var particles: [Particle] = []
    @Published var screenFlash: Double = 0
    @Published var screenShake: CGFloat = 0
    @Published var backgroundGlow: Double = 0
    @Published var burnProgress: Double = 0

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    var onComplete: (() -> Void)?

    func emit(from rect: CGRect, count: Int = 200) {
        // Фаза 1: Начальные искры из центра
        emitSparks(from: rect, count: count / 3)

        // Экранная вспышка
        withAnimation(.easeIn(duration: 0.15)) {
            screenFlash = 0.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.4)) {
                self.screenFlash = 0
            }
        }

        // Тряска экрана
        shakeScreen()

        // Фаза 2: Волна разрушения
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.emitDestructionWave(from: rect, count: count / 2)
            self.shakeScreen()
        }

        // Фаза 3: Пепел и дым
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.emitAshAndSmoke(from: rect, count: count / 3)
        }

        // Фоновое свечение
        withAnimation(.easeIn(duration: 0.5)) {
            backgroundGlow = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 1.5)) {
                self.backgroundGlow = 0
            }
        }

        // Прогресс горения
        withAnimation(.easeInOut(duration: 2.0)) {
            burnProgress = 1.0
        }

        startUpdateLoop()
    }

    func emitBurnEffect(from rect: CGRect) {
        let colors: [Color] = [.red, .orange, .yellow, Color(red: 1, green: 0.3, blue: 0)]

        let newParticles = (0..<80).map { _ -> Particle in
            let edge = Int.random(in: 0...3)
            var x: CGFloat
            var y: CGFloat
            var vx: CGFloat
            var vy: CGFloat

            switch edge {
            case 0: // top
                x = CGFloat.random(in: rect.minX...rect.maxX)
                y = rect.minY
                vx = CGFloat.random(in: -3...3)
                vy = CGFloat.random(in: 1...5)
            case 1: // bottom
                x = CGFloat.random(in: rect.minX...rect.maxX)
                y = rect.maxY
                vx = CGFloat.random(in: -3...3)
                vy = CGFloat.random(in: (-5)...(-1))
            case 2: // left
                x = rect.minX
                y = CGFloat.random(in: rect.minY...rect.maxY)
                vx = CGFloat.random(in: 1...5)
                vy = CGFloat.random(in: -3...3)
            default: // right
                x = rect.maxX
                y = CGFloat.random(in: rect.minY...rect.maxY)
                vx = CGFloat.random(in: (-5)...(-1))
                vy = CGFloat.random(in: -3...3)
            }

            let maxLife = Double.random(in: 1.0...2.5)
            return Particle(
                x: x, y: y,
                scale: CGFloat.random(in: 0.5...2.0),
                opacity: Double.random(in: 0.7...1.0),
                rotation: Double.random(in: 0...360),
                velocity: CGPoint(x: vx, y: vy),
                color: colors.randomElement() ?? .orange,
                type: .flame,
                lifetime: 0,
                maxLifetime: maxLife,
                angularVelocity: Double.random(in: -8...8),
                drag: 0.98,
                gravity: CGFloat.random(in: (-0.3)...(0.1))
            )
        }
        particles.append(contentsOf: newParticles)
    }

    private func emitSparks(from rect: CGRect, count: Int) {
        let centerX = rect.midX
        let centerY = rect.midY
        let sparkColors: [Color] = [.yellow, .orange, .white, Color(red: 1, green: 0.8, blue: 0.2)]

        let newParticles = (0..<count).map { _ -> Particle in
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 8...25)
            let maxLife = Double.random(in: 0.5...1.8)

            return Particle(
                x: centerX + CGFloat.random(in: -30...30),
                y: centerY + CGFloat.random(in: -30...30),
                scale: CGFloat.random(in: 0.3...1.5),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                velocity: CGPoint(
                    x: cos(angle) * speed,
                    y: sin(angle) * speed
                ),
                color: sparkColors.randomElement() ?? .yellow,
                type: .spark,
                lifetime: 0,
                maxLifetime: maxLife,
                angularVelocity: Double.random(in: -15...15),
                drag: 0.96,
                gravity: 0.2
            )
        }
        particles.append(contentsOf: newParticles)
    }

    private func emitDestructionWave(from rect: CGRect, count: Int) {
        let colors: [Color] = [.red, .orange, .yellow, Color(red: 1, green: 0.4, blue: 0), .white]

        let newParticles = (0..<count).map { _ -> Particle in
            let x = CGFloat.random(in: rect.minX...rect.maxX)
            let y = CGFloat.random(in: rect.minY...rect.maxY)
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 3...15)
            let maxLife = Double.random(in: 1.0...3.0)

            return Particle(
                x: x, y: y,
                scale: CGFloat.random(in: 0.5...3.0),
                opacity: Double.random(in: 0.6...1.0),
                rotation: Double.random(in: 0...360),
                velocity: CGPoint(
                    x: cos(angle) * speed,
                    y: sin(angle) * speed - CGFloat.random(in: 2...8)
                ),
                color: colors.randomElement() ?? .orange,
                type: [.ember, .fragment, .flame].randomElement() ?? .ember,
                lifetime: 0,
                maxLifetime: maxLife,
                angularVelocity: Double.random(in: -10...10),
                drag: 0.97,
                gravity: CGFloat.random(in: 0.05...0.3)
            )
        }
        particles.append(contentsOf: newParticles)
    }

    private func emitAshAndSmoke(from rect: CGRect, count: Int) {
        let ashColors: [Color] = [
            Color(white: 0.3), Color(white: 0.4), Color(white: 0.5),
            Color(red: 0.4, green: 0.35, blue: 0.3)
        ]
        let smokeColors: [Color] = [
            Color(white: 0.6).opacity(0.5), Color(white: 0.7).opacity(0.4),
            Color(white: 0.5).opacity(0.3)
        ]

        let ashParticles = (0..<count).map { _ -> Particle in
            let maxLife = Double.random(in: 2.0...5.0)
            return Particle(
                x: CGFloat.random(in: rect.minX...rect.maxX),
                y: CGFloat.random(in: rect.minY...rect.maxY),
                scale: CGFloat.random(in: 0.3...1.0),
                opacity: Double.random(in: 0.4...0.8),
                rotation: Double.random(in: 0...360),
                velocity: CGPoint(
                    x: CGFloat.random(in: -2...2),
                    y: CGFloat.random(in: (-6)...(-1))
                ),
                color: ashColors.randomElement() ?? .gray,
                type: .ash,
                lifetime: 0,
                maxLifetime: maxLife,
                angularVelocity: Double.random(in: -3...3),
                drag: 0.99,
                gravity: -0.02
            )
        }

        let smokeParticles = (0..<(count / 2)).map { _ -> Particle in
            let maxLife = Double.random(in: 2.0...4.0)
            return Particle(
                x: CGFloat.random(in: rect.minX...rect.maxX),
                y: rect.maxY * 0.6 + CGFloat.random(in: -50...50),
                scale: CGFloat.random(in: 3...8),
                opacity: Double.random(in: 0.1...0.3),
                rotation: Double.random(in: 0...360),
                velocity: CGPoint(
                    x: CGFloat.random(in: -1...1),
                    y: CGFloat.random(in: (-4)...(-1))
                ),
                color: smokeColors.randomElement() ?? .gray,
                type: .smoke,
                lifetime: 0,
                maxLifetime: maxLife,
                angularVelocity: Double.random(in: -1...1),
                drag: 0.995,
                gravity: -0.05
            )
        }

        particles.append(contentsOf: ashParticles)
        particles.append(contentsOf: smokeParticles)
    }

    private func shakeScreen() {
        let intensity: CGFloat = 8
        withAnimation(.linear(duration: 0.05)) { screenShake = intensity }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.linear(duration: 0.05)) { self.screenShake = -intensity * 0.8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.05)) { self.screenShake = intensity * 0.5 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.linear(duration: 0.05)) { self.screenShake = -intensity * 0.3 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.linear(duration: 0.1)) { self.screenShake = 0 }
        }
    }

    private func startUpdateLoop() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
        lastTimestamp = CACurrentMediaTime()
    }

    @objc private func update(_ link: CADisplayLink) {
        let dt = link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp

        for i in particles.indices {
            particles[i].lifetime += dt
            let lifeRatio = particles[i].lifetime / particles[i].maxLifetime

            // Physics
            particles[i].x += particles[i].velocity.x
            particles[i].y += particles[i].velocity.y
            particles[i].velocity.x *= particles[i].drag
            particles[i].velocity.y *= particles[i].drag
            particles[i].velocity.y += particles[i].gravity
            particles[i].rotation += particles[i].angularVelocity

            // Fade based on lifetime
            switch particles[i].type {
            case .spark:
                particles[i].opacity = max(0, 1.0 - lifeRatio * lifeRatio)
                particles[i].scale *= 0.99
            case .ember:
                particles[i].opacity = max(0, (1.0 - lifeRatio) * 0.9)
                if lifeRatio > 0.5 {
                    particles[i].scale *= 0.995
                }
            case .flame:
                particles[i].opacity = max(0, sin(lifeRatio * .pi) * 0.8)
                particles[i].scale *= (lifeRatio < 0.3 ? 1.01 : 0.995)
            case .ash:
                particles[i].opacity = max(0, (1.0 - lifeRatio * 0.7) * 0.6)
                particles[i].velocity.x += CGFloat.random(in: -0.3...0.3)
            case .smoke:
                particles[i].opacity = max(0, (1.0 - lifeRatio) * 0.25)
                particles[i].scale *= 1.003
            case .glow:
                particles[i].opacity = max(0, sin(lifeRatio * .pi))
            case .fragment:
                particles[i].opacity = max(0, 1.0 - lifeRatio)
                particles[i].angularVelocity *= 0.99
            case .dust:
                particles[i].opacity = max(0, (1.0 - lifeRatio) * 0.4)
                particles[i].velocity.x += CGFloat.random(in: -0.1...0.1)
            }
        }

        particles.removeAll { $0.lifetime >= $0.maxLifetime || $0.opacity <= 0.01 }

        if particles.isEmpty {
            displayLink?.invalidate()
            displayLink = nil
            onComplete?()
        }
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        particles = []
    }
}

// MARK: - Advanced Particle Effect View
struct ParticleEffectView: View {
    @ObservedObject var system: ParticleSystem

    var body: some View {
        ZStack {
            // Background glow
            if system.backgroundGlow > 0 {
                RadialGradient(
                    colors: [
                        Color.red.opacity(system.backgroundGlow * 0.4),
                        Color.orange.opacity(system.backgroundGlow * 0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
            }

            // Screen flash
            if system.screenFlash > 0 {
                Color.white
                    .opacity(system.screenFlash)
                    .ignoresSafeArea()
            }

            // Particles canvas
            Canvas { context, size in
                for particle in system.particles {
                    context.opacity = particle.opacity

                    switch particle.type {
                    case .spark:
                        drawSpark(context: &context, particle: particle)
                    case .ember:
                        drawEmber(context: &context, particle: particle)
                    case .flame:
                        drawFlame(context: &context, particle: particle)
                    case .ash:
                        drawAsh(context: &context, particle: particle)
                    case .smoke:
                        drawSmoke(context: &context, particle: particle)
                    case .glow:
                        drawGlow(context: &context, particle: particle)
                    case .fragment:
                        drawFragment(context: &context, particle: particle)
                    case .dust:
                        drawDust(context: &context, particle: particle)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawSpark(context: inout GraphicsContext, particle: Particle) {
        let s = particle.scale * 3
        // Bright center
        let center = CGRect(x: particle.x - s/2, y: particle.y - s/2, width: s, height: s)
        context.fill(Circle().path(in: center), with: .color(.white))
        // Glow
        let glow = CGRect(x: particle.x - s * 2, y: particle.y - s * 2, width: s * 4, height: s * 4)
        context.opacity = particle.opacity * 0.4
        context.fill(Circle().path(in: glow), with: .color(particle.color))
        // Trail
        let trailEnd = CGPoint(
            x: particle.x - particle.velocity.x * 2,
            y: particle.y - particle.velocity.y * 2
        )
        var trailPath = Path()
        trailPath.move(to: CGPoint(x: particle.x, y: particle.y))
        trailPath.addLine(to: trailEnd)
        context.opacity = particle.opacity * 0.6
        context.stroke(trailPath, with: .color(particle.color), lineWidth: s * 0.4)
    }

    private func drawEmber(context: inout GraphicsContext, particle: Particle) {
        let s = particle.scale * 4
        // Core
        let rect = CGRect(x: particle.x - s/2, y: particle.y - s/2, width: s, height: s)
        context.fill(Circle().path(in: rect), with: .color(particle.color))
        // Inner glow
        let innerGlow = CGRect(x: particle.x - s, y: particle.y - s, width: s * 2, height: s * 2)
        context.opacity = particle.opacity * 0.3
        context.fill(Circle().path(in: innerGlow), with: .color(particle.color))
    }

    private func drawFlame(context: inout GraphicsContext, particle: Particle) {
        let s = particle.scale * 5
        let rect = CGRect(x: particle.x - s/2, y: particle.y - s/2, width: s, height: s * 1.5)
        context.fill(Ellipse().path(in: rect), with: .color(particle.color))
        // Outer glow
        let outerGlow = rect.insetBy(dx: -s * 0.8, dy: -s * 0.8)
        context.opacity = particle.opacity * 0.2
        context.fill(Ellipse().path(in: outerGlow), with: .color(particle.color))
    }

    private func drawAsh(context: inout GraphicsContext, particle: Particle) {
        let s = particle.scale * 3
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: particle.x, y: particle.y)
        transform = transform.rotated(by: particle.rotation * .pi / 180)
        let rect = CGRect(x: -s/2, y: -s/4, width: s, height: s/2)
        var path = RoundedRectangle(cornerRadius: 1).path(in: rect)
        path = path.applying(transform)
        context.fill(path, with: .color(particle.color))
    }

    private func drawSmoke(context: inout GraphicsContext, particle: Particle) {
        let s = particle.scale * 10
        let rect = CGRect(x: particle.x - s/2, y: particle.y - s/2, width: s, height: s)
        context.fill(Circle().path(in: rect), with: .color(particle.color))
    }

    private func drawGlow(context: inout GraphicsContext, particle: Particle) {
        let s = particle.scale * 15
        let rect = CGRect(x: particle.x - s/2, y: particle.y - s/2, width: s, height: s)
        context.fill(Circle().path(in: rect), with: .color(particle.color))
    }

    private func drawFragment(context: inout GraphicsContext, particle: Particle) {
        let s = particle.scale * 5
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: particle.x, y: particle.y)
        transform = transform.rotated(by: particle.rotation * .pi / 180)
        let rect = CGRect(x: -s/2, y: -s/3, width: s, height: s * 0.6)
        var path = Rectangle().path(in: rect)
        path = path.applying(transform)
        context.fill(path, with: .color(particle.color))
        // Edge glow
        context.opacity = particle.opacity * 0.5
        context.stroke(path, with: .color(.orange), lineWidth: 0.5)
    }

    private func drawDust(context: inout GraphicsContext, particle: Particle) {
        let s = particle.scale * 2
        let rect = CGRect(x: particle.x - s/2, y: particle.y - s/2, width: s, height: s)
        context.fill(Circle().path(in: rect), with: .color(particle.color))
    }
}

// MARK: - Dissolve Effect Modifier
struct DissolveEffect: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? Double(1 - phase) : 1)
            .scaleEffect(isActive ? 1 + phase * 0.3 : 1)
            .blur(radius: isActive ? phase * 10 : 0)
            .onChange(of: isActive) { _, active in
                if active {
                    withAnimation(.easeOut(duration: 1.5)) {
                        phase = 1
                    }
                } else {
                    phase = 0
                }
            }
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

// MARK: - Pulse Ring Animation
struct PulseRing: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.8
    let color: Color

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    scale = 2.0
                    opacity = 0
                }
            }
    }
}

// MARK: - Fingerprint Animation
struct FingerprintView: View {
    @State private var drawProgress: CGFloat = 0
    @State private var glowOpacity: Double = 0
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(glowOpacity * 0.2))
                .frame(width: 120, height: 120)
                .blur(radius: 20)

            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .trim(from: 0, to: drawProgress * CGFloat.random(in: 0.4...0.9))
                    .stroke(
                        color.opacity(0.7 - Double(i) * 0.1),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: CGFloat(20 + i * 12), height: CGFloat(20 + i * 12))
                    .rotationEffect(.degrees(Double(i) * 30))
            }

            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .opacity(drawProgress)

            PulseRing(color: color)
                .frame(width: 80, height: 80)
                .opacity(glowOpacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                drawProgress = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1.0)) {
                glowOpacity = 1.0
            }
        }
    }
}

// MARK: - Heat Distortion Effect
struct HeatDistortionEffect: ViewModifier {
    let intensity: Double
    @State private var phase: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if intensity > 0 {
                    LinearGradient(
                        colors: [
                            Color.red.opacity(intensity * 0.1),
                            Color.orange.opacity(intensity * 0.05),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
            }
    }
}

// MARK: - Burn Edge Effect
struct BurnEdgeView: View {
    let progress: Double
    @State private var flicker: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Canvas { context, size in
                let burnHeight = h * progress
                let segments = 40

                for i in 0..<segments {
                    let xRatio = CGFloat(i) / CGFloat(segments)
                    let x = w * xRatio
                    let baseY = h - burnHeight
                    let noiseY = baseY + CGFloat.random(in: -20...20) * CGFloat(progress)
                    let segWidth = w / CGFloat(segments) + 2

                    // Burn glow
                    let glowRect = CGRect(x: x, y: noiseY - 10, width: segWidth, height: 20)
                    context.opacity = progress * 0.6 * flicker
                    context.fill(
                        Rectangle().path(in: glowRect),
                        with: .color(.orange)
                    )

                    // Burnt area
                    let burntRect = CGRect(x: x, y: noiseY, width: segWidth, height: h - noiseY)
                    context.opacity = progress * 0.8
                    context.fill(
                        Rectangle().path(in: burntRect),
                        with: .color(.black)
                    )
                }
            }
            .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
                flicker = Double.random(in: 0.7...1.0)
            }
        }
    }
}

extension View {
    func dissolveEffect(isActive: Bool) -> some View {
        modifier(DissolveEffect(isActive: isActive))
    }

    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }

    func heatDistortion(intensity: Double) -> some View {
        modifier(HeatDistortionEffect(intensity: intensity))
    }
}
