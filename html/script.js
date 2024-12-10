let isVisible = false;
let currentConversation = [];
let reportingStage = null;
let bugReport = {};
let isDarkMode = true;
let isDragging = false;
let currentX;
let currentY;
let initialX;
let initialY;
let xOffset = 0;
let yOffset = 0;

// Add scroll helper function at the top
function scrollToBottom() {
    const chatContainer = document.querySelector('.chat-container');
    const messages = document.getElementById('chat-messages');
    if (chatContainer && messages) {
        chatContainer.scrollTop = messages.scrollHeight;
    }
}

// Add theme toggle function
function toggleTheme() {
    isDarkMode = !isDarkMode;
    document.body.classList.toggle('dark-mode');
    const themeIcon = document.querySelector('#theme-btn i');
    themeIcon.className = isDarkMode ? 'fas fa-moon' : 'fas fa-sun';
    localStorage.setItem('darkMode', isDarkMode);
}

// Initialize the support interface
document.addEventListener('DOMContentLoaded', function() {
    const container = document.getElementById('support-container');
    const closeBtn = document.getElementById('close-btn');
    const themeBtn = document.getElementById('theme-btn');
    const sendBtn = document.getElementById('send-btn');
    const userInput = document.getElementById('user-input');
    const header = document.querySelector('.support-header');

    // Set title from config
    fetch(`https://${GetParentResourceName()}/getConfig`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });

    // Load saved theme
    isDarkMode = localStorage.getItem('darkMode') !== 'false';
    document.body.classList.toggle('dark-mode', isDarkMode);
    document.querySelector('#theme-btn i').className = isDarkMode ? 'fas fa-moon' : 'fas fa-sun';

    // Handle theme toggle
    themeBtn.addEventListener('click', toggleTheme);

    // Handle close button
    closeBtn.addEventListener('click', () => {
        const container = document.getElementById('support-container');
        
        // Add closing class without changing position
        container.classList.add('closing');
        
        // Wait for animation to finish before hiding
        setTimeout(() => {
            container.classList.add('hidden');
            container.classList.remove('closing');
            fetch(`https://${GetParentResourceName()}/closeSupport`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            });
            isVisible = false;
            resetConversation();
        }, 200); // Match animation duration
    });

    // Handle send button
    sendBtn.addEventListener('click', () => sendMessage());

    // Handle enter key
    userInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            sendMessage();
        }
    });

    // Handle escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && isVisible) {
            closeBtn.click();
        }
    });

    // Handle clear chat button
    const clearChatBtn = document.getElementById('clear-chat-btn');
    clearChatBtn.addEventListener('click', () => {
        const chatMessages = document.getElementById('chat-messages');
        chatMessages.innerHTML = '';
        currentConversation = [];
        
        // Notify server to clear chat history
        fetch(`https://${GetParentResourceName()}/clearChat`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        
        // Show confirmation notification
        showNotification('Chat history cleared');
    });

    // Handle clear context button
    const clearContextBtn = document.getElementById('clear-context-btn');
    clearContextBtn.addEventListener('click', () => {
        // Reset local state
        reportingStage = null;
        bugReport = {};
        
        // Notify server to clear context
        fetch(`https://${GetParentResourceName()}/clearContext`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        
        // Add system message
        addBotMessage("Context has been cleared. How can I help you?");
        
        // Show confirmation notification
        showNotification('Context cleared');
    });

    // Handle quick prompt buttons
    document.addEventListener('click', function(e) {
        if (e.target.closest('.quick-prompt-btn')) {
            const btn = e.target.closest('.quick-prompt-btn');
            const prompt = btn.dataset.prompt;
            const userInput = document.getElementById('user-input');
            
            // Set the input value
            userInput.value = prompt;
            userInput.focus();
            
            // Trigger input event to adjust height
            userInput.dispatchEvent(new Event('input'));
            
            // Optional: Send message immediately
            sendMessage();
        }
    });

    function dragStart(e) {
        if (e.target.closest('.header-actions')) return;
        
        const rect = container.getBoundingClientRect();
        initialX = e.clientX - rect.left;
        initialY = e.clientY - rect.top;
        
        isDragging = true;
        container.classList.add('dragging');
    }

    function drag(e) {
        if (!isDragging) return;
        
        e.preventDefault();
        
        const x = e.clientX - initialX;
        const y = e.clientY - initialY;
        
        // Keep window within viewport bounds
        const rect = container.getBoundingClientRect();
        const windowWidth = window.innerWidth;
        const windowHeight = window.innerHeight;
        
        const boundedX = Math.max(0, Math.min(x, windowWidth - rect.width));
        const boundedY = Math.max(0, Math.min(y, windowHeight - rect.height));
        
        container.style.left = boundedX + 'px';
        container.style.top = boundedY + 'px';
        container.style.transform = 'none';
    }

    function dragEnd(e) {
        if (!isDragging) return;
        
        isDragging = false;
        container.classList.remove('dragging');
        
        // Save position
        const rect = container.getBoundingClientRect();
        localStorage.setItem('aiSupport_position', JSON.stringify({
            x: rect.left,
            y: rect.top
        }));
    }

    // Add event listeners
    header.addEventListener('mousedown', dragStart, false);
    document.addEventListener('mousemove', drag, false);
    document.addEventListener('mouseup', dragEnd, false);

    // Prevent text selection and default drag
    header.addEventListener('selectstart', (e) => e.preventDefault());
    header.addEventListener('dragstart', (e) => e.preventDefault());

    // Restore saved position
    const savedPosition = localStorage.getItem('aiSupport_position');
    if (savedPosition) {
        const pos = JSON.parse(savedPosition);
        container.style.left = pos.x + 'px';
        container.style.top = pos.y + 'px';
        container.style.transform = 'none';
    }
});

// Handle messages from the game client
window.addEventListener('message', function(event) {
    const item = event.data;
    console.log('[AI-Support] Received message:', item); // Debug log
    
    if (!item || !item.type) {
        console.error('[AI-Support] Invalid message format:', item);
        return;
    }
    
    switch(item.type) {
        case 'show':
            const container = document.getElementById('support-container');
            container.classList.remove('hidden');
            isVisible = true;
            
            // Check for saved position
            const savedPosition = localStorage.getItem('aiSupport_position');
            if (savedPosition) {
                const pos = JSON.parse(savedPosition);
                container.style.left = pos.x + 'px';
                container.style.top = pos.y + 'px';
                container.style.transform = 'none';
            } else {
                // Reset to center if no saved position
                container.style.left = '50%';
                container.style.top = '50%';
                container.style.transform = 'translate(-50%, -50%)';
            }
            
            // Request chat history first
            fetch(`https://${GetParentResourceName()}/requestChatHistory`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            })
            .catch(() => {
                // Show welcome message immediately if history request fails
                addBotMessage("Hello! How can I help you today? You can report a bug, ask about game rules, or get map guidance.");
            });
            
            // Show initial message if no conversation exists
            if (!currentConversation.length) {
                addBotMessage("Hello! How can I help you today? You can report a bug, ask about game rules, or get map guidance.");
            }
            
            setTimeout(scrollToBottom, 100);
            break;
            
        case 'addBotMessage':
            if (item.message) {
                addBotMessage(item.message);
            } else {
                console.error('[AI-Support] Empty bot message');
                addBotMessage("Sorry, I encountered an error. Please try again.");
            }
            break;
            
        case 'notification':
            showNotification(item.message);
            break;
            
        case 'chatHistory':
            if (Array.isArray(item.messages) && item.messages.length > 0) {
                currentConversation = item.messages;
                loadChatHistory(item.messages);
            }
            break;
            
        case 'setConfig':
            if (item.config) {
                document.getElementById('support-title').textContent = item.config.title || 'AI Support';
            }
            break;
            
        case 'clearChat':
            const chatMessages = document.getElementById('chat-messages');
            chatMessages.innerHTML = '';
            currentConversation = [];
            break;
            
        default:
            console.log('[AI-Support] Unknown message type:', item.type);
    }
});

// Update the copyTextToClipboard function
async function copyTextToClipboard(text, button) {
    try {
        // Create temporary input element
        const tempInput = document.createElement('textarea');
        tempInput.value = text;
        tempInput.style.position = 'fixed';
        tempInput.style.opacity = '0';
        document.body.appendChild(tempInput);
        tempInput.select();
        
        // Try to copy using document.execCommand
        const success = document.execCommand('copy');
        document.body.removeChild(tempInput);
        
        if (success) {
            button.innerHTML = '<i class="fas fa-check"></i> Copied!';
        } else {
            throw new Error('Copy failed');
        }
        
        // Reset button after delay
        setTimeout(() => {
            button.innerHTML = '<i class="fas fa-copy"></i> Copy';
        }, 2000);
        
    } catch (err) {
        console.error('Copy failed:', err);
        button.innerHTML = '<i class="fas fa-times"></i> Failed';
        
        // Reset button after delay
        setTimeout(() => {
            button.innerHTML = '<i class="fas fa-copy"></i> Copy';
        }, 2000);
    }
}

// Update the code block copy functionality
function addCodeBlockCopy() {
    document.querySelectorAll('pre code').forEach(block => {
        if (!block.parentElement.querySelector('.copy-button')) {
            const button = document.createElement('button');
            button.className = 'copy-button';
            button.textContent = 'Copy';
            
            button.addEventListener('click', () => {
                copyTextToClipboard(block.textContent, button);
            });
            
            block.parentElement.appendChild(button);
        }
    });
}

// Add markdown parsing
function parseMarkdown(text) {
    // Headers
    text = text.replace(/^### (.*$)/gm, '<h3>$1</h3>');
    text = text.replace(/^## (.*$)/gm, '<h2>$1</h2>');
    text = text.replace(/^# (.*$)/gm, '<h1>$1</h1>');
    
    // Special handling for bullet points with "•"
    text = text.replace(/^• (.*$)/gm, '• $1');
    
    // Regular lists (only convert if not already using •)
    text = text.replace(/^(?!• )\* (.*$)/gm, '<li>$1</li>');
    text = text.replace(/^(?!• )- (.*$)/gm, '<li>$1</li>');
    text = text.replace(/^(\d+\. .*$)/gm, '<li>$1</li>');
    
    // Code blocks
    text = text.replace(/```(\w+)?([\s\S]*?)```/g, (match, lang, code) => {
        return `<pre><code class="language-${lang || ''}">${code.trim()}</code></pre>`;
    });
    
    // Inline code
    text = text.replace(/`([^`]+)`/g, '<code>$1</code>');
    
    return text;
}

// Update message adding functions to use markdown
function addUserMessage(message, save = true) {
    const chatMessages = document.getElementById('chat-messages');
    const messageElement = document.createElement('div');
    messageElement.className = 'message user-message';
    
    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content';
    contentDiv.innerHTML = parseMarkdown(message.replace(/\n/g, '<br>'));
    
    messageElement.appendChild(contentDiv);
    chatMessages.appendChild(messageElement);
    scrollToBottom();
    
    if (save) {
        currentConversation.push({ type: 'user', message });
        fetch(`https://${GetParentResourceName()}/saveChatMessage`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ type: 'user', message })
        }).catch(err => console.error('Error saving message:', err));
    }
    
    // Add code block copy buttons
    addCodeBlockCopy();
}

function addBotMessage(message, save = true) {
    if (!message || typeof message !== 'string') {
        console.error('[AI-Support] Invalid bot message:', message);
        message = "Sorry, I encountered an error. Please try again.";
    }
    
    const chatMessages = document.getElementById('chat-messages');
    const messageElement = document.createElement('div');
    messageElement.className = 'message bot-message';
    
    // Add message actions (copy button)
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'message-actions';
    const copyBtn = document.createElement('button');
    copyBtn.className = 'message-copy-btn';
    copyBtn.innerHTML = '<i class="fas fa-copy"></i> Copy';
    
    // Add event listener directly when creating the button
    copyBtn.addEventListener('click', () => {
        copyTextToClipboard(message, copyBtn);
    });
    
    actionsDiv.appendChild(copyBtn);
    messageElement.appendChild(actionsDiv);
    chatMessages.appendChild(messageElement);
    scrollToBottom();

    // Process message to preserve formatting and add markdown
    const formattedMessage = parseMarkdown(message
        .replace(/\n\n+/g, '\n\n')
        .split('\n')
        .map(line => line.trim())
        .join('\n'));

    // Split into characters while preserving line breaks
    const characters = [...formattedMessage];
    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content';
    
    setTimeout(() => {
        messageElement.appendChild(contentDiv);
        
        let i = 0;
        function typeNextCharacter() {
            if (i < characters.length) {
                if (characters[i] === '\n') {
                    contentDiv.appendChild(document.createElement('br'));
                    i++;
                    setTimeout(typeNextCharacter, 10);
                } else {
                    const span = document.createElement('span');
                    span.className = 'typewriter';
                    span.textContent = characters[i];
                    contentDiv.appendChild(span);
                    
                    requestAnimationFrame(() => span.classList.add('visible'));
                    
                    i++;
                    setTimeout(typeNextCharacter, 10);
                }
            } else {
                if (save) {
                    currentConversation.push({ type: 'bot', message });
                    fetch(`https://${GetParentResourceName()}/saveChatMessage`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ type: 'bot', message })
                    }).catch(err => console.error('Error saving message:', err));
                }
            }
            scrollToBottom();
        }
        
        typeNextCharacter();
    }, 300);
    
    // Add code block copy buttons after typing animation
    setTimeout(addCodeBlockCopy, 500);
}

function resetConversation() {
    reportingStage = null;
    bugReport = {};
    // Don't clear chat messages anymore
}

// Add notification function
function showNotification(message) {
    const notification = document.createElement('div');
    notification.className = 'notification';
    notification.textContent = message;
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.classList.add('fade-out');
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

// Add mutation observer to handle dynamic content
const chatObserver = new MutationObserver(scrollToBottom);

// Initialize observer when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    const chatMessages = document.getElementById('chat-messages');
    if (chatMessages) {
        chatObserver.observe(chatMessages, {
            childList: true,
            subtree: true
        });
    }
});

// Add function to load chat history
function loadChatHistory(messages) {
    const chatMessages = document.getElementById('chat-messages');
    chatMessages.innerHTML = ''; // Clear existing messages
    
    messages.forEach(msg => {
        if (msg.type === 'user') {
            addUserMessage(msg.message, false);
        } else {
            addBotMessage(msg.message, false);
        }
    });
    scrollToBottom();
}

function setTranslate(xPos, yPos, el) {
    // Keep window within viewport bounds
    const rect = el.getBoundingClientRect();
    const windowWidth = window.innerWidth;
    const windowHeight = window.innerHeight;
    
    // Adjust position to keep within bounds
    if (rect.left < 0) xPos -= rect.left;
    if (rect.right > windowWidth) xPos -= (rect.right - windowWidth);
    if (rect.top < 0) yPos -= rect.top;
    if (rect.bottom > windowHeight) yPos -= (rect.bottom - windowHeight);
    
    el.style.transform = `translate(${xPos}px, ${yPos}px)`;
}

// Add input auto-resize
document.getElementById('user-input').addEventListener('input', function() {
    this.style.height = 'auto';
    this.style.height = (this.scrollHeight) + 'px';
});

// Add loading state handling
function setLoading(loading) {
    const sendBtn = document.getElementById('send-btn');
    const userInput = document.getElementById('user-input');
    
    if (loading) {
        sendBtn.innerHTML = '<div class="loading-spinner"></div>';
        userInput.disabled = true;
    } else {
        sendBtn.innerHTML = '<i class="fas fa-paper-plane"></i>';
        userInput.disabled = false;
    }
}

// Update sendMessage to show loading state
async function sendMessage() {
    const userInput = document.getElementById('user-input');
    const message = userInput.value.trim();
    
    if (message === '') return;
    
    setLoading(true);
    
    try {
        addUserMessage(message);
        userInput.value = '';
        userInput.style.height = 'auto';
        
        await fetch(`https://${GetParentResourceName()}/handleMessage`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                message: message,
                stage: reportingStage,
                bugReport: bugReport
            })
        });
    } catch (err) {
        console.error('Error sending message:', err);
        addBotMessage("Sorry, I encountered an error. Please try again.");
    } finally {
        setLoading(false);
    }
} 