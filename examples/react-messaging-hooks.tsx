// CrewSnow React Messaging Hooks
// Complete React implementation with Realtime and Pagination

import React, { useState, useEffect, useCallback, useRef } from 'react'
import { createClient } from '@supabase/supabase-js'
import { RealtimeMessaging, Message } from './realtime-messaging'
import { MessagePagination, PaginationResult } from './message-pagination'

// ============================================================================
// SUPABASE CLIENT SETUP
// ============================================================================

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

// ============================================================================
// REACT HOOK: useRealtimeMessaging
// ============================================================================

export interface UseMessagingResult {
  messages: Message[]
  isLoading: boolean
  hasMore: boolean
  unreadCount: number
  sendMessage: (content: string, type?: Message['message_type']) => Promise<void>
  loadMoreMessages: () => Promise<void>
  markAsRead: () => Promise<void>
  error?: string
}

export function useRealtimeMessaging(
  matchId: string,
  currentUserId: string,
  initialLoadSize: number = 50
): UseMessagingResult {
  // State management
  const [messages, setMessages] = useState<Message[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [hasMore, setHasMore] = useState(false)
  const [unreadCount, setUnreadCount] = useState(0)
  const [error, setError] = useState<string>()
  
  // Refs for stable references
  const realtimeRef = useRef<RealtimeMessaging>()
  const paginationRef = useRef<MessagePagination>()
  const nextCursorRef = useRef<string>()

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  useEffect(() => {
    // Initialize services
    realtimeRef.current = new RealtimeMessaging(supabase)
    paginationRef.current = new MessagePagination(supabase)

    // Load initial messages
    loadInitialMessages()

    // Setup real-time subscription
    setupRealtimeSubscription()

    // Cleanup on unmount
    return () => {
      cleanup()
    }
  }, [matchId, currentUserId])

  // ============================================================================
  // MESSAGE LOADING
  // ============================================================================

  const loadInitialMessages = useCallback(async () => {
    if (!paginationRef.current) return

    try {
      setIsLoading(true)
      setError(undefined)

      // Use cursor-based pagination for initial load
      const result = await paginationRef.current.getMessagesByCursor(
        matchId,
        undefined,
        initialLoadSize
      )

      setMessages(result.data)
      setHasMore(result.hasMore)
      nextCursorRef.current = result.nextCursor

      // Load unread count
      await updateUnreadCount()

      console.log(`✅ Loaded ${result.data.length} initial messages`)
    } catch (err) {
      console.error('❌ Erreur chargement initial:', err)
      setError('Erreur lors du chargement des messages')
    } finally {
      setIsLoading(false)
    }
  }, [matchId, initialLoadSize])

  const loadMoreMessages = useCallback(async () => {
    if (!paginationRef.current || !hasMore || isLoading) return

    try {
      setIsLoading(true)
      
      // Load next page using cursor
      const result = await paginationRef.current.getMessagesByCursor(
        matchId,
        nextCursorRef.current,
        initialLoadSize
      )

      // Append to existing messages (avoid duplicates)
      setMessages(prev => {
        const existingIds = new Set(prev.map(m => m.id))
        const newMessages = result.data.filter(m => !existingIds.has(m.id))
        return [...prev, ...newMessages]
      })

      setHasMore(result.hasMore)
      nextCursorRef.current = result.nextCursor

      console.log(`✅ Loaded ${result.data.length} more messages`)
    } catch (err) {
      console.error('❌ Erreur chargement plus:', err)
      setError('Erreur lors du chargement des messages supplémentaires')
    } finally {
      setIsLoading(false)
    }
  }, [matchId, hasMore, isLoading, initialLoadSize])

  // ============================================================================
  // REAL-TIME SUBSCRIPTION
  // ============================================================================

  const setupRealtimeSubscription = useCallback(() => {
    if (!realtimeRef.current) return

    // Subscribe to new messages according to specifications
    realtimeRef.current.subscribeToMessages(matchId, (newMessage) => {
      console.log('📨 Nouveau message temps réel:', newMessage)
      
      // Add new message to the beginning (most recent first)
      setMessages(prev => {
        // Check if message already exists (prevent duplicates)
        const exists = prev.some(m => m.id === newMessage.id)
        if (exists) return prev
        
        return [newMessage, ...prev]
      })

      // Update unread count if message is from other user
      if (newMessage.sender_id !== currentUserId) {
        setUnreadCount(prev => prev + 1)
      }
    })

    // Subscribe to read receipts
    realtimeRef.current.subscribeToReadReceipts(matchId, () => {
      updateUnreadCount()
    })
  }, [matchId, currentUserId])

  // ============================================================================
  // MESSAGE OPERATIONS
  // ============================================================================

  const sendMessage = useCallback(async (
    content: string,
    type: Message['message_type'] = 'text'
  ) => {
    if (!realtimeRef.current) return

    try {
      const sentMessage = await realtimeRef.current.sendMessage(
        matchId,
        currentUserId,
        content,
        type
      )

      if (sentMessage) {
        // Optionally add to local state immediately (optimistic update)
        // The real-time subscription will also trigger, but this provides instant feedback
        setMessages(prev => [sentMessage, ...prev])
        console.log('✅ Message envoyé avec succès')
      }
    } catch (err) {
      console.error('❌ Erreur envoi message:', err)
      setError('Erreur lors de l\'envoi du message')
    }
  }, [matchId, currentUserId])

  const markAsRead = useCallback(async () => {
    if (!realtimeRef.current) return

    try {
      await realtimeRef.current.markMessagesAsRead(matchId, currentUserId)
      setUnreadCount(0)
      console.log('✅ Messages marqués comme lus')
    } catch (err) {
      console.error('❌ Erreur marquage lecture:', err)
    }
  }, [matchId, currentUserId])

  const updateUnreadCount = useCallback(async () => {
    if (!paginationRef.current) return

    try {
      const { data } = await supabase.rpc('get_unread_messages_count', {
        p_user_id: currentUserId
      })

      const matchData = data?.find((item: any) => item.match_id === matchId)
      setUnreadCount(matchData?.unread_count || 0)
    } catch (err) {
      console.error('❌ Erreur mise à jour comptage:', err)
    }
  }, [matchId, currentUserId])

  // ============================================================================
  // CLEANUP
  // ============================================================================

  const cleanup = useCallback(() => {
    if (realtimeRef.current) {
      realtimeRef.current.unsubscribeFromMessages(matchId)
      realtimeRef.current.unsubscribeFromReadReceipts(matchId)
    }
  }, [matchId])

  return {
    messages,
    isLoading,
    hasMore,
    unreadCount,
    sendMessage,
    loadMoreMessages,
    markAsRead,
    error,
  }
}

// ============================================================================
// REACT COMPONENT EXAMPLE
// ============================================================================

interface ChatProps {
  matchId: string
  currentUserId: string
}

export const ChatComponent: React.FC<ChatProps> = ({ matchId, currentUserId }) => {
  const {
    messages,
    isLoading,
    hasMore,
    unreadCount,
    sendMessage,
    loadMoreMessages,
    markAsRead,
    error
  } = useRealtimeMessaging(matchId, currentUserId)

  const [newMessage, setNewMessage] = useState('')
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const chatContainerRef = useRef<HTMLDivElement>(null)

  // Auto-scroll to bottom on new messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  // Mark as read when component becomes visible
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible' && unreadCount > 0) {
        markAsRead()
      }
    }

    document.addEventListener('visibilitychange', handleVisibilityChange)
    
    // Mark as read immediately if visible
    if (unreadCount > 0) {
      markAsRead()
    }

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange)
    }
  }, [unreadCount, markAsRead])

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newMessage.trim()) return

    await sendMessage(newMessage.trim())
    setNewMessage('')
  }

  const handleScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const { scrollTop, scrollHeight, clientHeight } = e.currentTarget
    
    // Load more messages when user scrolls near the top
    if (scrollTop < 100 && hasMore && !isLoading) {
      loadMoreMessages()
    }
  }

  if (error) {
    return <div className="error">❌ {error}</div>
  }

  return (
    <div className="chat-container">
      {/* Header with unread count */}
      <div className="chat-header">
        <h3>Match Chat</h3>
        {unreadCount > 0 && (
          <span className="unread-badge">{unreadCount} non-lus</span>
        )}
      </div>

      {/* Messages container with infinite scroll */}
      <div 
        className="messages-container"
        onScroll={handleScroll}
        ref={chatContainerRef}
        style={{ 
          height: '400px', 
          overflowY: 'auto', 
          display: 'flex', 
          flexDirection: 'column-reverse' 
        }}
      >
        {/* Loading indicator */}
        {isLoading && (
          <div className="loading-indicator">⏳ Chargement...</div>
        )}
        
        {/* Load more button/indicator */}
        {hasMore && !isLoading && (
          <button 
            onClick={loadMoreMessages}
            className="load-more-button"
          >
            📜 Charger plus de messages
          </button>
        )}

        {/* Messages list */}
        <div className="messages-list">
          {messages.map((message, index) => (
            <div
              key={message.id}
              className={`message ${
                message.sender_id === currentUserId ? 'own-message' : 'other-message'
              }`}
            >
              <div className="message-content">
                {message.content}
              </div>
              <div className="message-meta">
                <span className="sender">{message.sender_username}</span>
                <span className="timestamp">
                  {new Date(message.created_at).toLocaleTimeString()}
                </span>
                {message.is_read && message.sender_id === currentUserId && (
                  <span className="read-indicator">✓</span>
                )}
              </div>
            </div>
          ))}
        </div>

        <div ref={messagesEndRef} />
      </div>

      {/* Message input form */}
      <form onSubmit={handleSendMessage} className="message-form">
        <input
          type="text"
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          placeholder="Tapez votre message..."
          maxLength={2000}
          disabled={isLoading}
          className="message-input"
        />
        <button 
          type="submit" 
          disabled={!newMessage.trim() || isLoading}
          className="send-button"
        >
          📤 Envoyer
        </button>
      </form>
    </div>
  )
}

// ============================================================================
// REACT HOOK: useMatchesList (for main matches screen)
// ============================================================================

export interface MatchWithMessages {
  id: string
  user1_id: string
  user2_id: string
  created_at: string
  other_user: {
    id: string
    username: string
    photo_url?: string
  }
  last_message?: {
    content: string
    created_at: string
    sender_id: string
  }
  unread_count: number
}

export function useMatchesList(currentUserId: string) {
  const [matches, setMatches] = useState<MatchWithMessages[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string>()

  const realtimeRef = useRef<RealtimeMessaging>()

  useEffect(() => {
    realtimeRef.current = new RealtimeMessaging(supabase)
    
    // Load initial matches
    loadMatches()

    // Subscribe to new matches
    realtimeRef.current.subscribeToMatches(currentUserId, (newMatch) => {
      console.log('🎉 Nouveau match:', newMatch)
      loadMatches() // Reload to get complete match info
    })

    return () => {
      realtimeRef.current?.unsubscribeAll()
    }
  }, [currentUserId])

  const loadMatches = useCallback(async () => {
    try {
      setIsLoading(true)
      setError(undefined)

      // Use the comprehensive view for matches with unread counts
      const { data, error: queryError } = await supabase
        .from('matches_with_unread')
        .select('*')
        .or(`user1_id.eq.${currentUserId},user2_id.eq.${currentUserId}`)
        .order('last_message_at', { ascending: false, nullsFirst: false })

      if (queryError) {
        throw queryError
      }

      // Transform data to include other_user info
      const transformedMatches: MatchWithMessages[] = data.map(match => ({
        id: match.match_id,
        user1_id: match.user1_id,
        user2_id: match.user2_id,
        created_at: match.matched_at,
        other_user: {
          id: match.user1_id === currentUserId ? match.user2_id : match.user1_id,
          username: match.user1_id === currentUserId ? match.user2_username : match.user1_username,
        },
        last_message: match.last_message_content ? {
          content: match.last_message_content,
          created_at: match.last_message_at,
          sender_id: match.last_message_sender,
        } : undefined,
        unread_count: match.user1_id === currentUserId ? match.user1_unread_count : match.user2_unread_count,
      }))

      setMatches(transformedMatches)
    } catch (err: any) {
      console.error('❌ Erreur chargement matches:', err)
      setError('Erreur lors du chargement des conversations')
    } finally {
      setIsLoading(false)
    }
  }, [currentUserId])

  return {
    matches,
    isLoading,
    error,
    refreshMatches: loadMatches,
  }
}

// ============================================================================
// REACT COMPONENT: MatchesList
// ============================================================================

interface MatchesListProps {
  currentUserId: string
  onMatchSelect: (matchId: string) => void
}

export const MatchesList: React.FC<MatchesListProps> = ({ 
  currentUserId, 
  onMatchSelect 
}) => {
  const { matches, isLoading, error, refreshMatches } = useMatchesList(currentUserId)

  if (error) {
    return (
      <div className="matches-error">
        ❌ {error}
        <button onClick={refreshMatches}>🔄 Réessayer</button>
      </div>
    )
  }

  if (isLoading) {
    return <div className="matches-loading">⏳ Chargement des conversations...</div>
  }

  return (
    <div className="matches-list">
      <div className="matches-header">
        <h2>💬 Vos Conversations</h2>
        <button onClick={refreshMatches} className="refresh-button">
          🔄 Actualiser
        </button>
      </div>

      {matches.length === 0 ? (
        <div className="no-matches">
          💔 Aucune conversation pour le moment.
          <br />
          Continuez à swiper pour trouver des matches !
        </div>
      ) : (
        <div className="matches-grid">
          {matches.map((match) => (
            <div
              key={match.id}
              className={`match-card ${match.unread_count > 0 ? 'has-unread' : ''}`}
              onClick={() => onMatchSelect(match.id)}
            >
              <div className="match-user">
                <div className="user-avatar">
                  {match.other_user.photo_url ? (
                    <img src={match.other_user.photo_url} alt={match.other_user.username} />
                  ) : (
                    <div className="avatar-placeholder">
                      {match.other_user.username[0].toUpperCase()}
                    </div>
                  )}
                </div>
                <div className="user-info">
                  <h3>{match.other_user.username}</h3>
                  {match.unread_count > 0 && (
                    <span className="unread-badge">{match.unread_count}</span>
                  )}
                </div>
              </div>

              {match.last_message && (
                <div className="last-message">
                  <p>{match.last_message.content}</p>
                  <span className="timestamp">
                    {new Date(match.last_message.created_at).toLocaleString()}
                  </span>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

// ============================================================================
// COMPLETE MESSAGING APP EXAMPLE
// ============================================================================

export const MessagingApp: React.FC<{ currentUserId: string }> = ({ currentUserId }) => {
  const [selectedMatchId, setSelectedMatchId] = useState<string | null>(null)

  return (
    <div className="messaging-app" style={{ display: 'flex', height: '100vh' }}>
      {/* Left sidebar: matches list */}
      <div className="matches-sidebar" style={{ width: '300px', borderRight: '1px solid #ccc' }}>
        <MatchesList
          currentUserId={currentUserId}
          onMatchSelect={setSelectedMatchId}
        />
      </div>

      {/* Right panel: selected chat */}
      <div className="chat-panel" style={{ flex: 1 }}>
        {selectedMatchId ? (
          <ChatComponent
            matchId={selectedMatchId}
            currentUserId={currentUserId}
          />
        ) : (
          <div className="no-chat-selected">
            💬 Sélectionnez une conversation pour commencer à chatter !
          </div>
        )}
      </div>
    </div>
  )
}

// ============================================================================
// CSS STYLES (basic styling for the examples)
// ============================================================================

export const messagingStyles = `
  .chat-container {
    display: flex;
    flex-direction: column;
    height: 100%;
  }

  .chat-header {
    padding: 1rem;
    background: #f5f5f5;
    border-bottom: 1px solid #ddd;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .unread-badge {
    background: #ff4444;
    color: white;
    border-radius: 12px;
    padding: 2px 8px;
    font-size: 0.8em;
  }

  .messages-container {
    flex: 1;
    padding: 1rem;
    background: #fafafa;
  }

  .message {
    margin-bottom: 1rem;
    padding: 0.5rem;
    border-radius: 8px;
    max-width: 80%;
  }

  .own-message {
    background: #007bff;
    color: white;
    align-self: flex-end;
    margin-left: auto;
  }

  .other-message {
    background: white;
    border: 1px solid #ddd;
  }

  .message-meta {
    font-size: 0.8em;
    margin-top: 0.25rem;
    opacity: 0.7;
  }

  .message-form {
    padding: 1rem;
    background: white;
    border-top: 1px solid #ddd;
    display: flex;
    gap: 0.5rem;
  }

  .message-input {
    flex: 1;
    padding: 0.5rem;
    border: 1px solid #ddd;
    border-radius: 4px;
  }

  .send-button {
    padding: 0.5rem 1rem;
    background: #007bff;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .load-more-button {
    width: 100%;
    padding: 0.5rem;
    background: #f8f9fa;
    border: 1px solid #ddd;
    border-radius: 4px;
    cursor: pointer;
    margin-bottom: 1rem;
  }

  .matches-list {
    padding: 1rem;
  }

  .match-card {
    padding: 1rem;
    border: 1px solid #ddd;
    border-radius: 8px;
    margin-bottom: 0.5rem;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .match-card:hover {
    background: #f8f9fa;
  }

  .match-card.has-unread {
    border-left: 4px solid #007bff;
    font-weight: bold;
  }
`

export default useRealtimeMessaging
