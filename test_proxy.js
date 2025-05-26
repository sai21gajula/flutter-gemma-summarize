// Quick test script to verify the proxy server is working
const fetch = require('node-fetch');

async function testProxy() {
    console.log('🧪 Testing Proxy Server...\n');
    
    // Test health endpoint
    try {
        const healthResponse = await fetch('http://localhost:3001/health');
        const healthData = await healthResponse.text();
        console.log('✅ Health check:', healthData);
    } catch (error) {
        console.log('❌ Health check failed:', error.message);
        return;
    }
    
    // Test API endpoint with dummy data
    try {
        const testResponse = await fetch('http://localhost:3001/api/gemma', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                apiKey: 'test-key',
                model: 'test-model',
                contents: [
                    {
                        parts: [
                            { text: 'Hello world' }
                        ]
                    }
                ],
                generationConfig: {
                    temperature: 0.7,
                    maxOutputTokens: 100
                }
            })
        });
        
        console.log('📡 API endpoint status:', testResponse.status);
        if (!testResponse.ok) {
            const errorData = await testResponse.text();
            console.log('❌ API endpoint error:', errorData);
        } else {
            const responseData = await testResponse.text();
            console.log('✅ API endpoint response:', responseData);
        }
    } catch (error) {
        console.log('❌ API endpoint test failed:', error.message);
    }
}

testProxy();
