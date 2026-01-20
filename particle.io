<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gesture Controlled Particle System</title>
    <style>
        body {
            margin: 0;
            overflow: hidden;
            background-color: #050505;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            color: white;
        }
        #canvas-container {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 1;
        }
        #video-container {
            position: absolute;
            bottom: 20px;
            right: 20px;
            width: 160px;
            height: 120px;
            z-index: 2;
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-radius: 8px;
            overflow: hidden;
            background: black;
            transform: scaleX(-1); /* Mirror the local video */
        }
        #input-video {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        #ui-layer {
            position: absolute;
            top: 20px;
            left: 20px;
            z-index: 10;
            pointer-events: none;
        }
        
        /* AI Panel Styles */
        #ai-panel {
            position: absolute;
            bottom: 20px;
            left: 20px;
            z-index: 10;
            background: rgba(0, 0, 0, 0.7);
            padding: 15px;
            border-radius: 12px;
            border: 1px solid rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(10px);
            width: 300px;
            transition: transform 0.3s ease;
        }
        #ai-panel h2 {
            margin: 0 0 10px 0;
            font-size: 1rem;
            color: #ccc;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        #ai-input {
            width: 100%;
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            color: white;
            padding: 8px;
            border-radius: 6px;
            margin-bottom: 10px;
            box-sizing: border-box;
            font-family: inherit;
        }
        #ai-input:focus {
            outline: none;
            border-color: #00ffff;
        }
        .ai-btn-group {
            display: flex;
            gap: 8px;
            margin-bottom: 8px;
        }
        .ai-btn {
            flex: 1;
            padding: 8px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.2s;
            color: white;
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .btn-shape {
            background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
        }
        .btn-shape:hover { filter: brightness(1.2); }
        
        .btn-vibe {
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
        }
        .btn-vibe:hover { filter: brightness(1.2); }

        .btn-save {
            background: rgba(255, 255, 255, 0.15);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .btn-save:hover { background: rgba(255, 255, 255, 0.3); }

        .btn-loading {
            opacity: 0.7;
            cursor: wait;
            animation: pulse 1s infinite;
        }

        h1 {
            margin: 0;
            font-size: 1.5rem;
            text-transform: uppercase;
            letter-spacing: 2px;
            text-shadow: 0 0 10px rgba(0, 255, 255, 0.5);
        }
        p {
            font-size: 0.9rem;
            color: #aaa;
            max-width: 300px;
            background: rgba(0, 0, 0, 0.5);
            padding: 10px;
            border-radius: 4px;
        }
        .status-dot {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background-color: red;
            margin-right: 8px;
            box-shadow: 0 0 5px red;
        }
        .status-dot.active {
            background-color: #0f0;
            box-shadow: 0 0 5px #0f0;
        }
        #loading {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            font-size: 2rem;
            color: cyan;
            z-index: 20;
            text-align: center;
        }
        #current-shape {
            position: absolute;
            bottom: 30px;
            left: 50%;
            transform: translateX(-50%);
            font-size: 1.2rem;
            background: rgba(0,0,0,0.6);
            padding: 10px 20px;
            border-radius: 20px;
            border: 1px solid rgba(255,255,255,0.2);
            z-index: 10;
            text-transform: uppercase;
            letter-spacing: 1px;
            transition: all 0.3s ease;
        }
        #file-input { display: none; }
        @keyframes pulse {
            0% { opacity: 0.7; }
            50% { opacity: 0.4; }
            100% { opacity: 0.7; }
        }
    </style>
    <!-- Three.js -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <!-- MediaPipe Hands -->
    <script src="https://cdn.jsdelivr.net/npm/@mediapipe/camera_utils/camera_utils.js" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/@mediapipe/control_utils/control_utils.js" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/@mediapipe/drawing_utils/drawing_utils.js" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/@mediapipe/hands/hands.js" crossorigin="anonymous"></script>
</head>
<body>

    <div id="loading">Initializing Camera & Particles...<br><span style="font-size:1rem; color:white">Please allow camera access.</span></div>

    <div id="ui-layer">
        <h1><span id="cam-status" class="status-dot"></span>Holo-Particles</h1>
        <p>
            🖐 <strong>Move Hand:</strong> Attract/Repel<br>
            👌 <strong>Pinch:</strong> Change Shape<br>
            ✨ <strong>AI:</strong> Describe a shape or vibe below!
        </p>
    </div>

    <div id="ai-panel">
        <h2>AI Command Center</h2>
        <input type="text" id="ai-input" placeholder="e.g. 'Spiral Galaxy' or 'Volcanic'">
        
        <div class="ai-btn-group">
            <button class="ai-btn btn-shape" onclick="generateAI('shape')">Dream Shape</button>
            <button class="ai-btn btn-vibe" onclick="generateAI('vibe')">Dream Vibe</button>
        </div>
        
        <div class="ai-btn-group">
            <button class="ai-btn btn-save" onclick="saveProject()">💾 Save Proj</button>
            <button class="ai-btn btn-save" onclick="document.getElementById('file-input').click()">📂 Load Proj</button>
        </div>
        
        <div class="ai-btn-group">
            <button class="ai-btn btn-save" onclick="exportOBJ()">🧊 Export 3D</button>
            <button class="ai-btn btn-save" onclick="saveSnapshot()">📷 Snapshot</button>
        </div>

        <input type="file" id="file-input" accept=".json" onchange="loadProject(this)">
        <div id="ai-status" style="font-size: 0.8rem; color: #888; margin-top: 5px; height: 1.2em;"></div>
    </div>

    <div id="current-shape">Sphere</div>

    <div id="canvas-container"></div>
    
    <div id="video-container">
        <video id="input-video"></video>
    </div>

    <script>
        // --- CONFIGURATION ---
        const PARTICLE_COUNT = 25000;
        const CAM_FOV = 60;
        const PARTICLE_SIZE = 0.6; 
        const INTERACTION_RADIUS = 30; 
        const apiKey = "AIzaSyDj8WUKv3x96u_yQ9vGoBrMpGodsCsvJK8"; // Provided by runtime environment
        
        // --- GLOBAL VARIABLES ---
        let scene, camera, renderer, particles, geometry, materials;
        let positions, colors; // Buffer arrays
        let targetPositions = []; // Array of positions for the current target shape
        let currentShapeIndex = 0;
        let time = 0;
        let timeSpeed = 0.01; 
        
        // Interaction State
        const mouse = new THREE.Vector2();
        const handPos = new THREE.Vector3(0, 0, 0); 
        const handPosWorld = new THREE.Vector3(0, 0, 0); 
        let isHandDetected = false;
        let isPinching = false;
        let pinchTimer = 0; 
        let expansionFactor = 1.0; 
        
        const shapes = [
            { name: "Sphere", func: getSpherePoint, code: null },
            { name: "Heart", func: getHeartPoint, code: null },
            { name: "Saturn", func: getSaturnPoint, code: null },
            { name: "DNA Helix", func: getHelixPoint, code: null },
            { name: "Torus Knot", func: getTorusKnotPoint, code: null },
            { name: "Cube Matrix", func: getCubePoint, code: null }
        ];

        // --- INIT THREE.JS ---
        function initThree() {
            const container = document.getElementById('canvas-container');
            
            scene = new THREE.Scene();
            scene.fog = new THREE.FogExp2(0x000000, 0.02);

            camera = new THREE.PerspectiveCamera(CAM_FOV, window.innerWidth / window.innerHeight, 0.1, 1000);
            camera.position.z = 50;

            renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, preserveDrawingBuffer: true });
            renderer.setPixelRatio(window.devicePixelRatio);
            renderer.setSize(window.innerWidth, window.innerHeight);
            container.appendChild(renderer.domElement);

            createParticles();

            const ambientLight = new THREE.AmbientLight(0x404040);
            scene.add(ambientLight);

            window.addEventListener('resize', onWindowResize, false);
            document.addEventListener('mousemove', onMouseMove, false);
            document.addEventListener('click', (e) => {
                if(e.target.closest('#ai-panel') || e.target.closest('button') || e.target.closest('input')) return;
                switchShape((currentShapeIndex + 1) % shapes.length);
            });
        }

        // --- PARTICLE SYSTEM ---
        function createParticles() {
            geometry = new THREE.BufferGeometry();
            positions = new Float32Array(PARTICLE_COUNT * 3);
            colors = new Float32Array(PARTICLE_COUNT * 3);
            targetPositions = new Float32Array(PARTICLE_COUNT * 3);

            for (let i = 0; i < PARTICLE_COUNT; i++) {
                positions[i * 3] = (Math.random() - 0.5) * 100;
                positions[i * 3 + 1] = (Math.random() - 0.5) * 100;
                positions[i * 3 + 2] = (Math.random() - 0.5) * 100;

                const color = new THREE.Color();
                color.setHSL(i / PARTICLE_COUNT, 1.0, 0.7); 
                colors[i * 3] = color.r;
                colors[i * 3 + 1] = color.g;
                colors[i * 3 + 2] = color.b;
            }

            geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
            geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

            const sprite = generateSprite();
            const material = new THREE.PointsMaterial({
                size: PARTICLE_SIZE,
                map: sprite,
                vertexColors: true,
                blending: THREE.AdditiveBlending,
                depthWrite: false,
                transparent: true,
                opacity: 0.95
            });

            particles = new THREE.Points(geometry, material);
            scene.add(particles);

            calculateShape(0);
        }

        function updateColors(colorStart, colorEnd) {
             const colorsAttr = geometry ? geometry.attributes.color : colors;
             if(!colorsAttr) return;

             const c1 = new THREE.Color(colorStart);
             const c2 = new THREE.Color(colorEnd);
             const arr = geometry ? colorsAttr.array : colors;

             for (let i = 0; i < PARTICLE_COUNT; i++) {
                 const mixed = c1.clone().lerp(c2, i / PARTICLE_COUNT);
                 arr[i * 3] = mixed.r;
                 arr[i * 3 + 1] = mixed.g;
                 arr[i * 3 + 2] = mixed.b;
             }
             if(geometry) geometry.attributes.color.needsUpdate = true;
        }

        function generateSprite() {
            const canvas = document.createElement('canvas');
            canvas.width = 32;
            canvas.height = 32;
            const context = canvas.getContext('2d');
            const gradient = context.createRadialGradient(16, 16, 0, 16, 16, 16);
            gradient.addColorStop(0, 'rgba(255,255,255,1)');
            gradient.addColorStop(0.4, 'rgba(255,255,255,1)');
            gradient.addColorStop(0.6, 'rgba(255,255,255,0.4)');
            gradient.addColorStop(1, 'rgba(0,0,0,0)');
            context.fillStyle = gradient;
            context.fillRect(0, 0, 32, 32);
            const texture = new THREE.Texture(canvas);
            texture.needsUpdate = true;
            return texture;
        }

        // --- MATH SHAPES ---
        function calculateShape(index) {
            const func = shapes[index].func;
            for (let i = 0; i < PARTICLE_COUNT; i++) {
                const p = func(i, PARTICLE_COUNT);
                targetPositions[i * 3] = p.x;
                targetPositions[i * 3 + 1] = p.y;
                targetPositions[i * 3 + 2] = p.z;
            }
            document.getElementById('current-shape').innerText = shapes[index].name;
            document.getElementById('current-shape').style.transform = "translateX(-50%) scale(1.2)";
            setTimeout(() => {
                document.getElementById('current-shape').style.transform = "translateX(-50%) scale(1)";
            }, 200);
        }

        function getSpherePoint(i, total) {
            const r = 15;
            const phi = Math.acos(-1 + (2 * i) / total);
            const theta = Math.sqrt(total * Math.PI) * phi;
            return { x: r * Math.cos(theta) * Math.sin(phi), y: r * Math.sin(theta) * Math.sin(phi), z: r * Math.cos(phi) };
        }
        function getHeartPoint(i, total) {
            const t = (i / total) * Math.PI * 2;
            const x = 16 * Math.pow(Math.sin(t), 3);
            const y = 13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t);
            const z = (Math.random() - 0.5) * 5 * (Math.abs(x)/16); 
            const scale = 0.8;
            return { x: x * scale, y: y * scale, z: z + (Math.random() - 0.5) * 5 };
        }
        function getSaturnPoint(i, total) {
            const ratio = 0.7; 
            if (i < total * ratio) return getSpherePoint(i, total * ratio); 
            const r = 20 + Math.random() * 10;
            const theta = Math.random() * Math.PI * 2;
            return { x: r * Math.cos(theta), y: (Math.random() - 0.5) * 2, z: r * Math.sin(theta) };
        }
        function getHelixPoint(i, total) {
            const t = i * 0.1; const r = 10; const h = 40; const y = ((i / total) - 0.5) * h;
            const offset = (i % 2 === 0) ? 0 : Math.PI;
            return { x: r * Math.cos(t + offset), y: y, z: r * Math.sin(t + offset) };
        }
        function getTorusKnotPoint(i, total) {
            const t = (i / total) * Math.PI * 20; const p = 2; const q = 3; const scale = 5;
            const r = Math.cos(q * t) + 2;
            return { x: scale * r * Math.cos(p * t), y: scale * r * Math.sin(p * t), z: scale * -Math.sin(q * t) };
        }
        function getCubePoint(i, total) {
            const size = 30; const half = size / 2;
            return { x: Math.random() * size - half, y: Math.random() * size - half, z: Math.random() * size - half };
        }

        function switchShape(newIndex) {
            currentShapeIndex = newIndex;
            calculateShape(currentShapeIndex);
        }

        // --- ANIMATION LOOP ---
        function animate() {
            requestAnimationFrame(animate);
            time += timeSpeed; 

            const positionsAttr = geometry.attributes.position;
            const currentPosArray = positionsAttr.array;

            let attractor = new THREE.Vector3(0,0,0);
            if (isHandDetected) attractor.copy(handPosWorld);
            else {
                const vec = new THREE.Vector3(mouse.x, mouse.y, 0.5);
                vec.unproject(camera);
                vec.sub(camera.position).normalize();
                const distance = -camera.position.z / vec.z;
                attractor.copy(camera.position).add(vec.multiplyScalar(distance));
            }

            for (let i = 0; i < PARTICLE_COUNT; i++) {
                const idx = i * 3;
                let tx = targetPositions[idx] * expansionFactor;
                let ty = targetPositions[idx+1] * expansionFactor;
                let tz = targetPositions[idx+2] * expansionFactor;
                const cosT = Math.cos(time * 0.2);
                const sinT = Math.sin(time * 0.2);
                const rx = tx * cosT - tz * sinT;
                const rz = tx * sinT + tz * cosT;
                tx = rx; tz = rz;

                const px = currentPosArray[idx];
                const py = currentPosArray[idx+1];
                const pz = currentPosArray[idx+2];
                const dx = attractor.x - px;
                const dy = attractor.y - py;
                const dz = attractor.z - pz;
                const distSq = dx*dx + dy*dy + dz*dz;

                let fx = 0, fy = 0, fz = 0;
                if (distSq < INTERACTION_RADIUS * INTERACTION_RADIUS) {
                    const dist = Math.sqrt(distSq);
                    const force = (INTERACTION_RADIUS - dist) / INTERACTION_RADIUS;
                    fx += -dx * force * 0.1; fy += -dy * force * 0.1; fz += -dz * force * 0.1;
                    fx += dy * force * 0.2; fy -= dx * force * 0.2;
                }
                currentPosArray[idx] += (tx - px + fx) * 0.05;
                currentPosArray[idx+1] += (ty - py + fy) * 0.05;
                currentPosArray[idx+2] += (tz - pz + fz) * 0.05;
            }
            positionsAttr.needsUpdate = true;
            particles.rotation.z = Math.sin(time * 0.1) * 0.1;
            renderer.render(scene, camera);
        }

        function onWindowResize() {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        }
        function onMouseMove(event) {
            mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
            mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
        }

        // --- GEMINI AI & FILE IO ---
        async function generateAI(type) {
            const input = document.getElementById('ai-input').value;
            const status = document.getElementById('ai-status');
            
            if (!input.trim()) {
                status.innerText = "Please describe something first!";
                status.style.color = "#ff6b6b";
                return;
            }

            status.innerText = "Consulting the AI...";
            status.style.color = "#4db8ff";
            
            const btn = type === 'shape' ? document.querySelector('.btn-shape') : document.querySelector('.btn-vibe');
            const originalText = btn.innerText;
            btn.innerText = "Dreaming...";
            btn.classList.add('btn-loading');

            try {
                const response = await callGeminiAPI(input, type);
                if (type === 'shape') {
                    applyGeneratedShape(response, input);
                    status.innerText = `Morphed into: ${input}`;
                } else {
                    applyGeneratedVibe(response);
                    status.innerText = `Vibe set: ${input}`;
                }
                status.style.color = "#0f0";
            } catch (error) {
                console.error(error);
                status.innerText = "AI Error. Try again.";
                status.style.color = "#ff6b6b";
            } finally {
                btn.innerText = originalText;
                btn.classList.remove('btn-loading');
            }
        }

        async function callGeminiAPI(prompt, type) {
            const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=${apiKey}`;
            let systemPrompt = "";
            let userPrompt = "";

            if (type === 'shape') {
                systemPrompt = `You are a 3D geometry expert. You MUST return ONLY the body of a JavaScript function. The function signature is implicitly (i, total). Return object {x, y, z}. Coords approx -20 to 20. No function wrapper. Example: 'const t = (i/total)*Math.PI*2; return {x: 10*Math.cos(t), y: 10*Math.sin(t), z: 0};'`;
                userPrompt = `Write the function body to form this shape: ${prompt}`;
            } else {
                systemPrompt = `You are a visual design expert. Return valid JSON ONLY. No markdown. Structure: { "color1": "hex", "color2": "hex", "speed": number, "size": number }.`;
                userPrompt = `Generate a color palette and physics parameters for: ${prompt}`;
            }

            const payload = {
                contents: [{ parts: [{ text: userPrompt }] }],
                systemInstruction: { parts: [{ text: systemPrompt }] }
            };
            if (type === 'vibe') payload.generationConfig = { responseMimeType: "application/json" };

            const response = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
            const data = await response.json();
            if (!response.ok) throw new Error("API Error");
            return data.candidates[0].content.parts[0].text;
        }

        function applyGeneratedShape(codeString, name) {
            let cleanCode = codeString.replace(/```javascript/g, '').replace(/```/g, '').trim();
            try {
                const newFunc = new Function('i', 'total', cleanCode);
                const newShape = { name: "✨ " + name, func: newFunc, code: cleanCode };
                shapes.push(newShape);
                switchShape(shapes.length - 1);
            } catch (e) {
                throw new Error("Invalid Code Generated");
            }
        }

        function applyGeneratedVibe(jsonString) {
            const data = JSON.parse(jsonString);
            if (data.color1 && data.color2) updateColors(data.color1, data.color2);
            if (data.speed) timeSpeed = data.speed;
            if (data.size && particles) particles.material.size = data.size;
        }

        // --- SAVE / LOAD / EXPORT ---
        function saveProject() {
            // Save current shape index and parameters
            const currentShape = shapes[currentShapeIndex];
            const data = {
                currentShapeName: currentShape.name,
                isCustomShape: !!currentShape.code,
                customShapeCode: currentShape.code || null,
                colors: {
                    c1: "#" + new THREE.Color().fromArray(geometry.attributes.color.array, 0).getHexString(),
                    c2: "#" + new THREE.Color().fromArray(geometry.attributes.color.array, (PARTICLE_COUNT-1)*3).getHexString()
                },
                speed: timeSpeed,
                size: particles.material.size
            };
            downloadFile('holo-project.json', JSON.stringify(data));
        }

        function loadProject(input) {
            const file = input.files[0];
            if(!file) return;
            const reader = new FileReader();
            reader.onload = function(e) {
                try {
                    const data = JSON.parse(e.target.result);
                    // Restore Vibe
                    updateColors(data.colors.c1, data.colors.c2);
                    timeSpeed = data.speed;
                    particles.material.size = data.size;

                    // Restore Shape
                    if(data.isCustomShape && data.customShapeCode) {
                        applyGeneratedShape(data.customShapeCode, data.currentShapeName.replace("✨ ", ""));
                    } else {
                        // Find standard shape
                        const idx = shapes.findIndex(s => s.name === data.currentShapeName);
                        if(idx !== -1) switchShape(idx);
                    }
                    document.getElementById('ai-status').innerText = "Project Loaded!";
                } catch(err) {
                    alert("Error loading project: " + err);
                }
            };
            reader.readAsText(file);
        }

        function exportOBJ() {
            let output = "# Holo-Particles Export\n";
            const pos = geometry.attributes.position.array;
            for(let i=0; i<PARTICLE_COUNT; i++) {
                output += `v ${pos[i*3]} ${pos[i*3+1]} ${pos[i*3+2]}\n`;
            }
            downloadFile('holo-model.obj', output);
        }

        function saveSnapshot() {
            renderer.render(scene, camera);
            const link = document.createElement('a');
            link.download = 'holo-art.png';
            link.href = renderer.domElement.toDataURL('image/png');
            link.click();
        }

        function downloadFile(filename, content) {
            const blob = new Blob([content], {type: 'text/plain'});
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = filename;
            link.click();
        }

        // --- MEDIAPIPE ---
        function initMediaPipe() {
            const videoElement = document.getElementById('input-video');
            const hands = new Hands({locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/hands/${file}`});
            hands.setOptions({ maxNumHands: 2, modelComplexity: 1, minDetectionConfidence: 0.5, minTrackingConfidence: 0.5 });
            hands.onResults(onHandsResults);
            const cameraUtils = new Camera(videoElement, {
                onFrame: async () => await hands.send({image: videoElement}),
                width: 320, height: 240
            });
            cameraUtils.start().then(() => {
                document.getElementById('loading').style.display = 'none';
                document.getElementById('cam-status').classList.add('active');
            }).catch(err => {
                document.getElementById('loading').innerHTML = "Camera failed.<br>Using Mouse Mode.";
                setTimeout(() => { document.getElementById('loading').style.display = 'none'; }, 2000);
            });
        }

        function onHandsResults(results) {
            isHandDetected = results.multiHandLandmarks && results.multiHandLandmarks.length > 0;
            const camStatus = document.getElementById('cam-status');
            if(isHandDetected && !camStatus.classList.contains('active')) camStatus.classList.add('active');
            
            if (isHandDetected) {
                const landmarks = results.multiHandLandmarks[0];
                const indexTip = landmarks[8];
                const thumbTip = landmarks[4];
                const x = (1 - indexTip.x) * 2 - 1; 
                const y = -(indexTip.y * 2 - 1);    
                const vector = new THREE.Vector3(x, y, 0.5);
                vector.unproject(camera);
                const dir = vector.sub(camera.position).normalize();
                const distance = -camera.position.z / dir.z;
                handPosWorld.copy(camera.position.clone().add(dir.multiplyScalar(distance)));

                const pinchDist = Math.hypot(indexTip.x - thumbTip.x, indexTip.y - thumbTip.y);
                if (pinchDist < 0.05) { 
                    if (!isPinching && Date.now() - pinchTimer > 500) {
                        isPinching = true; pinchTimer = Date.now();
                        switchShape((currentShapeIndex + 1) % shapes.length);
                    }
                } else isPinching = false;

                if (results.multiHandLandmarks.length === 2) {
                    const hand1 = results.multiHandLandmarks[0][9];
                    const hand2 = results.multiHandLandmarks[1][9];
                    const dist = Math.hypot(hand1.x - hand2.x, hand1.y - hand2.y);
                    expansionFactor = 0.5 + (dist * 2.5);
                } else expansionFactor = expansionFactor + (1.0 - expansionFactor) * 0.1;
            } else expansionFactor = expansionFactor + (1.0 - expansionFactor) * 0.1;
        }

        initThree();
        initMediaPipe();
        animate();
    </script>
</body>
</html>
