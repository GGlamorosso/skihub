// CrewSnow Read Receipts Client Implementation
// 5. Accusés de lecture (table match_reads)

import { createClient, SupabaseClient } from '@supabase/supabase-js'

export interface ReadReceipt {
  match_id: string
  user_id: string
  last_read_at: string
  last_read_message_id?: string
}

export interface MessageReadStatus {
  message_id: string
  is_read_by_other_user: boolean
  read_at?: string
  other_user_last_read: string
}

// ============================================================================
// 5. ACCUSÉS DE LECTURE - IMPLÉMENTATION CLIENT
// ============================================================================

export class ReadReceiptsManager {
  private supabase: SupabaseClient

  constructor(supabaseClient: SupabaseClient) {
    this.supabase = supabaseClient
  }

  // ============================================================================
  // Core function: Mark messages as read (selon spécifications)
  // ============================================================================

  /**
   * Marquer les messages comme lus lorsqu'un utilisateur ouvre ou lit une conversation
   * Selon spécification exacte : 
   * await supabase.from('match_reads').upsert({ match_id, user_id: currentUserId, last_read_at: new Date().toISOString() })
   */
  async markConversationAsRead(
    matchId: string,
    currentUserId: string,
    lastMessageId?: string
  ): Promise<boolean> {
    try {
      console.log(`📖 Marquage conversation ${matchId} comme lue pour user ${currentUserId}`)

      // ✅ Implémentation exacte selon spécification
      const { error } = await this.supabase
        .from('match_reads')
        .upsert({
          match_id: matchId,
          user_id: currentUserId,
          last_read_at: new Date().toISOString(),
          ...(lastMessageId && { last_read_message_id: lastMessageId })
        })

      if (error) {
        console.error('❌ Erreur marquage lecture:', error)
        return false
      }

      console.log('✅ Messages marqués comme lus')
      
      // Optionnel : aussi mettre à jour les messages individuels (compatibilité)
      if (lastMessageId) {
        await this.updateIndividualMessageStatus(matchId, currentUserId, lastMessageId)
      }

      return true
    } catch (error) {
      console.error('❌ Exception marquage lecture:', error)
      return false
    }
  }

  // ============================================================================
  // Helper: Update individual message read status (bonus)
  // ============================================================================

  private async updateIndividualMessageStatus(
    matchId: string,
    userId: string,
    lastReadMessageId: string
  ): Promise<void> {
    try {
      // Marquer tous les messages jusqu'au dernier lu comme lus
      const { error } = await this.supabase
        .from('messages')
        .update({ 
          is_read: true,
          read_at: new Date().toISOString()
        })
        .eq('match_id', matchId)
        .neq('sender_id', userId) // Ne pas marquer ses propres messages
        .lte('created_at', 
          // Get timestamp of last read message
          this.supabase
            .from('messages')
            .select('created_at')
            .eq('id', lastReadMessageId)
            .single()
        )

      if (error) {
        console.warn('⚠️ Mise à jour messages individuels échouée:', error)
      }
    } catch (error) {
      console.warn('⚠️ Exception mise à jour messages:', error)
    }
  }

  // ============================================================================
  // Get read status for messages in a conversation
  // ============================================================================

  async getReadStatusForMatch(
    matchId: string,
    currentUserId: string
  ): Promise<{
    otherUserLastRead: string | null
    myLastRead: string | null
    otherUserId: string | null
  }> {
    try {
      // Get the other user in this match
      const { data: matchData } = await this.supabase
        .from('matches')
        .select('user1_id, user2_id')
        .eq('id', matchId)
        .single()

      if (!matchData) {
        throw new Error('Match not found')
      }

      const otherUserId = matchData.user1_id === currentUserId ? matchData.user2_id : matchData.user1_id

      // Get read receipts for both users
      const { data: readReceipts } = await this.supabase
        .from('match_reads')
        .select('user_id, last_read_at, last_read_message_id')
        .eq('match_id', matchId)
        .in('user_id', [currentUserId, otherUserId])

      const myRead = readReceipts?.find(r => r.user_id === currentUserId)
      const otherRead = readReceipts?.find(r => r.user_id === otherUserId)

      return {
        otherUserLastRead: otherRead?.last_read_at || null,
        myLastRead: myRead?.last_read_at || null,
        otherUserId: otherUserId
      }
    } catch (error) {
      console.error('❌ Erreur récupération statut lecture:', error)
      return {
        otherUserLastRead: null,
        myLastRead: null,
        otherUserId: null
      }
    }
  }

  // ============================================================================
  // Check if messages are read by other user
  // ============================================================================

  async getMessageReadStatuses(
    matchId: string,
    currentUserId: string,
    messageIds: string[]
  ): Promise<Map<string, MessageReadStatus>> {
    try {
      const readStatusMap = new Map<string, MessageReadStatus>()

      // Get other user's read status
      const { otherUserLastRead, otherUserId } = await this.getReadStatusForMatch(
        matchId, 
        currentUserId
      )

      if (!otherUserLastRead || !otherUserId) {
        // No read receipts available
        messageIds.forEach(id => {
          readStatusMap.set(id, {
            message_id: id,
            is_read_by_other_user: false,
            read_at: undefined,
            other_user_last_read: ''
          })
        })
        return readStatusMap
      }

      // Get messages with timestamps to compare with read receipts
      const { data: messages } = await this.supabase
        .from('messages')
        .select('id, created_at, sender_id')
        .eq('match_id', matchId)
        .in('id', messageIds)

      if (!messages) {
        return readStatusMap
      }

      // Determine read status for each message
      const otherUserLastReadTime = new Date(otherUserLastRead)

      messages.forEach(msg => {
        const messageTime = new Date(msg.created_at)
        const isReadByOther = 
          msg.sender_id === currentUserId && // Only check read status for own messages
          messageTime <= otherUserLastReadTime

        readStatusMap.set(msg.id, {
          message_id: msg.id,
          is_read_by_other_user: isReadByOther,
          read_at: isReadByOther ? otherUserLastRead : undefined,
          other_user_last_read: otherUserLastRead
        })
      })

      return readStatusMap
    } catch (error) {
      console.error('❌ Erreur statuts lecture messages:', error)
      return new Map()
    }
  }

  // ============================================================================
  // Auto-mark as read when user is viewing conversation
  // ============================================================================

  setupAutoMarkAsRead(
    matchId: string,
    currentUserId: string,
    options: {
      markReadOnFocus?: boolean
      markReadOnScroll?: boolean
      debounceMs?: number
    } = {}
  ): () => void {
    const {
      markReadOnFocus = true,
      markReadOnScroll = true,
      debounceMs = 1000
    } = options

    let debounceTimeout: NodeJS.Timeout | null = null
    let lastMessageId: string | null = null

    // Debounced mark as read function
    const debouncedMarkAsRead = () => {
      if (debounceTimeout) {
        clearTimeout(debounceTimeout)
      }

      debounceTimeout = setTimeout(() => {
        this.markConversationAsRead(matchId, currentUserId, lastMessageId || undefined)
      }, debounceMs)
    }

    // Update last message when new messages arrive
    const updateLastMessage = (messageId: string) => {
      lastMessageId = messageId
      debouncedMarkAsRead()
    }

    // Focus/visibility change handler
    const handleVisibilityChange = () => {
      if (markReadOnFocus && !document.hidden) {
        debouncedMarkAsRead()
      }
    }

    // Scroll handler (mark as read when scrolling)
    const handleScroll = () => {
      if (markReadOnScroll) {
        debouncedMarkAsRead()
      }
    }

    // Setup event listeners
    if (markReadOnFocus) {
      document.addEventListener('visibilitychange', handleVisibilityChange)
      window.addEventListener('focus', handleVisibilityChange)
    }

    // Return cleanup function
    return () => {
      if (debounceTimeout) {
        clearTimeout(debounceTimeout)
      }
      
      if (markReadOnFocus) {
        document.removeEventListener('visibilitychange', handleVisibilityChange)
        window.removeEventListener('focus', handleVisibilityChange)
      }
    }
  }

  // ============================================================================
  // Get unread counts for all matches of a user
  // ============================================================================

  async getUnreadCounts(currentUserId: string): Promise<Array<{
    match_id: string
    unread_count: number
    last_message_content: string | null
    last_message_at: string | null
    other_user_username: string
  }>> {
    try {
      // Use the database function if available
      const { data, error } = await this.supabase.rpc('get_unread_messages_count', {
        p_user_id: currentUserId
      })

      if (error) {
        console.error('❌ Erreur comptage non-lus:', error)
        return []
      }

      return data || []
    } catch (error) {
      console.error('❌ Exception comptage non-lus:', error)
      return []
    }
  }

  // ============================================================================
  // Realtime subscription for read receipts
  // ============================================================================

  subscribeToReadReceipts(
    matchId: string,
    onReadReceiptUpdate: (receipt: ReadReceipt) => void
  ): any {
    console.log(`📖 Abonnement accusés de réception pour match ${matchId}`)

    const channel = this.supabase
      .channel(`read_receipts:match:${matchId}`)
      .on(
        'postgres_changes',
        {
          event: '*', // INSERT, UPDATE, DELETE
          schema: 'public',
          table: 'match_reads',
          filter: `match_id=eq.${matchId}`,
        },
        (payload) => {
          console.log('📖 Accusé réception mis à jour:', payload.new)
          onReadReceiptUpdate(payload.new as ReadReceipt)
        }
      )
      .subscribe()

    return channel
  }
}

// ============================================================================
// REACT HOOK: useReadReceipts
// ============================================================================

import { useState, useEffect, useCallback } from 'react'

export function useReadReceipts(matchId: string, currentUserId: string) {
  const [readReceipts, setReadReceipts] = useState<Map<string, MessageReadStatus>>(new Map())
  const [otherUserLastRead, setOtherUserLastRead] = useState<string | null>(null)
  const [unreadCount, setUnreadCount] = useState(0)

  const readReceiptsManager = new ReadReceiptsManager(supabase)

  // ============================================================================
  // Mark as read when user opens/views conversation
  // ============================================================================

  const markAsRead = useCallback(async (lastMessageId?: string) => {
    const success = await readReceiptsManager.markConversationAsRead(
      matchId,
      currentUserId,
      lastMessageId
    )

    if (success) {
      setUnreadCount(0)
      console.log('✅ Conversation marquée comme lue')
    }

    return success
  }, [matchId, currentUserId])

  // ============================================================================
  // Auto mark as read on focus/visibility
  // ============================================================================

  useEffect(() => {
    // Setup auto-mark as read when user is viewing
    const cleanup = readReceiptsManager.setupAutoMarkAsRead(
      matchId,
      currentUserId,
      {
        markReadOnFocus: true,
        markReadOnScroll: false,
        debounceMs: 2000 // Wait 2 seconds before marking as read
      }
    )

    return cleanup
  }, [matchId, currentUserId])

  // ============================================================================
  // Subscribe to read receipt changes
  // ============================================================================

  useEffect(() => {
    const channel = readReceiptsManager.subscribeToReadReceipts(
      matchId,
      (receipt) => {
        // Update read receipts state
        if (receipt.user_id !== currentUserId) {
          // Other user's read receipt updated
          setOtherUserLastRead(receipt.last_read_at)
          console.log('📖 Autre utilisateur a lu jusqu\'à:', receipt.last_read_at)
        }
      }
    )

    return () => {
      if (channel) {
        supabase.removeChannel(channel)
      }
    }
  }, [matchId, currentUserId])

  // ============================================================================
  // Load initial read status
  // ============================================================================

  useEffect(() => {
    const loadInitialReadStatus = async () => {
      const status = await readReceiptsManager.getReadStatusForMatch(
        matchId,
        currentUserId
      )
      
      setOtherUserLastRead(status.otherUserLastRead)
    }

    loadInitialReadStatus()
  }, [matchId, currentUserId])

  // ============================================================================
  // Check if specific messages are read
  // ============================================================================

  const getMessageReadStatus = useCallback(async (messageIds: string[]) => {
    const statusMap = await readReceiptsManager.getMessageReadStatuses(
      matchId,
      currentUserId,
      messageIds
    )
    
    setReadReceipts(statusMap)
    return statusMap
  }, [matchId, currentUserId])

  return {
    markAsRead,
    getMessageReadStatus,
    readReceipts,
    otherUserLastRead,
    unreadCount,
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

// Example 1: Basic usage in React component
export function ChatScreenWithReadReceipts({ matchId, currentUserId }: {
  matchId: string
  currentUserId: string
}) {
  const { markAsRead, readReceipts, otherUserLastRead } = useReadReceipts(matchId, currentUserId)
  const [messages, setMessages] = useState<Message[]>([])

  // Mark as read when component mounts (user opens conversation)
  useEffect(() => {
    markAsRead()
  }, [markAsRead])

  // Mark as read when new messages arrive and user is viewing
  useEffect(() => {
    if (messages.length > 0 && document.hasFocus()) {
      const latestMessage = messages[0]
      markAsRead(latestMessage.id)
    }
  }, [messages, markAsRead])

  return (
    <div>
      {messages.map(message => (
        <div key={message.id} className="message">
          <div>{message.content}</div>
          
          {/* Show read receipt indicator for own messages */}
          {message.sender_id === currentUserId && (
            <div className="read-indicator">
              {otherUserLastRead && 
               new Date(message.created_at) <= new Date(otherUserLastRead) ? (
                <span>✓✓ Lu</span>
              ) : (
                <span>✓ Envoyé</span>
              )}
            </div>
          )}
        </div>
      ))}
    </div>
  )
}

// Example 2: Automatic read marking with intersection observer
export function useAutoReadMarking(
  matchId: string,
  currentUserId: string,
  containerRef: React.RefObject<HTMLElement>
) {
  const readReceiptsManager = new ReadReceiptsManager(supabase)
  
  useEffect(() => {
    if (!containerRef.current) return

    // Use Intersection Observer to mark messages as read when they come into view
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            const messageId = entry.target.getAttribute('data-message-id')
            if (messageId) {
              // Debounce to avoid too many calls
              setTimeout(() => {
                readReceiptsManager.markConversationAsRead(matchId, currentUserId, messageId)
              }, 1000)
            }
          }
        })
      },
      {
        root: containerRef.current,
        threshold: 0.5 // Message 50% visible = considered read
      }
    )

    // Observe all message elements
    const messageElements = containerRef.current.querySelectorAll('[data-message-id]')
    messageElements.forEach(el => observer.observe(el))

    return () => observer.disconnect()
  }, [matchId, currentUserId, containerRef])
}

// Example 3: Integration with existing messaging hook
export function useMessagingWithReadReceipts(matchId: string, currentUserId: string) {
  const messaging = useRealtimeMessaging(matchId, currentUserId)
  const readReceipts = useReadReceipts(matchId, currentUserId)

  // Enhanced send message with auto-read marking
  const sendMessageWithReadMarking = useCallback(async (
    content: string,
    type: Message['message_type'] = 'text'
  ) => {
    const message = await messaging.sendMessage(content, type)
    
    if (message) {
      // Mark our own message as "read" immediately (we sent it)
      await readReceipts.markAsRead(message.id)
    }
    
    return message
  }, [messaging.sendMessage, readReceipts.markAsRead])

  return {
    ...messaging,
    ...readReceipts,
    sendMessage: sendMessageWithReadMarking,
  }
}

export default ReadReceiptsManager
