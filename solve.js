const fs = require('fs');

async function test() {
    const res = await fetch('https://desarambipuji-jember.com/api/surat', {
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
        }
    });
    const html = await res.text();
    const scriptMatch = html.match(/<script nonce="[^"]+">([\s\S]*?)<\/script>/g);
    const script = scriptMatch[scriptMatch.length - 1];
    
    // Look at j and H
    const ts = html.match(/'ts','(\d+)'/)[1];
    const action = html.match(/l='([^']+)'/)[1];
    console.log('ts:', ts, 'action:', action);
}
test();
