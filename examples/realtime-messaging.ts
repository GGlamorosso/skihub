// CrewSnow Realtime Messaging Implementation
// TypeScript examples for real-time messaging with postgres_changes

import { createClient, SupabaseClient, RealtimeChannel } from '@supabase/supabase-js'

// ============================================================================
// 3. ACTIVATION REALTIME AVEC POSTGRES_CHANGES
// ============================================================================

// Configuration client Supabase
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

// Création du client
const supabase = createClient(SUPABASE_URL, ANON_KEY)

// ============================================================================
// EXAMPLE 1: Basic Message Subscription (selon spécifications exactes)
// ============================================================================

// Pour un match particulier
const matchId = '...' // uuid de la conversation

const channel = supabase
  .channel(`messages:match:${matchId}`)
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'messages',
      filter: `match_id=eq.${matchId}`,
    },
    payload => {
      // payload.new contient le message inséré
      console.log('Nouveau message :', payload.new)
    },
  )
  .subscribe()

// ============================================================================
// ADVANCED REALTIME MESSAGING CLASS
// ============================================================================

export interface Message {
  id: string
  match_id: string
  sender_id: string
  content: string
  message_type: 'text' | 'image' | 'location' | 'system'
  created_at: string
  is_read: boolean
  read_at?: string
}

export interface Match {
  id: string
  user1_id: string
  user2_id: string
  created_at: string
  is_active: boolean
}

export class RealtimeMessaging {
  private supabase: SupabaseClient
  private channels: Map<string, RealtimeChannel> = new Map()
  private messageHandlers: Map<string, (message: Message) => void> = new Map()
  private matchHandlers: Map<string, (match: Match) => void> = new Map()

  constructor(supabaseClient: SupabaseClient) {
    this.supabase = supabaseClient
  }

  // ============================================================================
  // Subscribe to messages for a specific match
  // ============================================================================
  
  subscribeToMessages(
    matchId: string,
    onNewMessage: (message: Message) => void
  ): RealtimeChannel {
    // Unsubscribe existing channel if any
    this.unsubscribeFromMessages(matchId)
    
    // Create new channel with specific match filter
    const channelName = `messages:match:${matchId}`
    const channel = this.supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `match_id=eq.${matchId}`,
        },
        (payload) => {
          const newMessage = payload.new as Message
          console.log('📨 Nouveau message reçu:', newMessage)
          onNewMessage(newMessage)
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'messages',
          filter: `match_id=eq.${matchId}`,
        },
        (payload) => {
          const updatedMessage = payload.new as Message
          console.log('✏️ Message mis à jour:', updatedMessage)
          // Handle message updates (e.g., read status)
          onNewMessage(updatedMessage)
        }
      )
      .subscribe((status) => {
        console.log(`📡 Channel ${channelName} status:`, status)
      })

    // Store references
    this.channels.set(matchId, channel)
    this.messageHandlers.set(matchId, onNewMessage)
    
    return channel
  }

  // ============================================================================
  // Subscribe to new matches for current user
  // ============================================================================
  
  subscribeToMatches(
    userId: string,
    onNewMatch: (match: Match) => void
  ): RealtimeChannel {
    const channelName = `matches:user:${userId}`
    
    // Remove existing channel
    const existingChannel = this.channels.get(`matches:${userId}`)
    if (existingChannel) {
      existingChannel.unsubscribe()
    }

    const channel = this.supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'matches',
          filter: `user1_id=eq.${userId}`,
        },
        (payload) => {
          const newMatch = payload.new as Match
          console.log('🎉 Nouveau match (user1):', newMatch)
          onNewMatch(newMatch)
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'matches',
          filter: `user2_id=eq.${userId}`,
        },
        (payload) => {
          const newMatch = payload.new as Match
          console.log('🎉 Nouveau match (user2):', newMatch)
          onNewMatch(newMatch)
        }
      )
      .subscribe((status) => {
        console.log(`📡 Matches channel status:`, status)
      })

    this.channels.set(`matches:${userId}`, channel)
    this.matchHandlers.set(userId, onNewMatch)

    return channel
  }

  // ============================================================================
  // Subscribe to read receipts (match_reads table)
  // ============================================================================
  
  subscribeToReadReceipts(
    matchId: string,
    onReadUpdate: (readReceipt: any) => void
  ): RealtimeChannel {
    const channelName = `reads:match:${matchId}`

    const channel = this.supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: '*', // INSERT, UPDATE, DELETE
          schema: 'public',
          table: 'match_reads',
          filter: `match_id=eq.${matchId}`,
        },
        (payload) => {
          console.log('📖 Read receipt update:', payload)
          onReadUpdate(payload.new)
        }
      )
      .subscribe((status) => {
        console.log(`📖 Read receipts channel status:`, status)
      })

    this.channels.set(`reads:${matchId}`, channel)
    return channel
  }

  // ============================================================================
  // Unsubscribe methods
  // ============================================================================
  
  unsubscribeFromMessages(matchId: string): void {
    const channel = this.channels.get(matchId)
    if (channel) {
      channel.unsubscribe()
      this.channels.delete(matchId)
      this.messageHandlers.delete(matchId)
      console.log(`🔕 Unsubscribed from messages for match ${matchId}`)
    }
  }

  unsubscribeFromMatches(userId: string): void {
    const channel = this.channels.get(`matches:${userId}`)
    if (channel) {
      channel.unsubscribe()
      this.channels.delete(`matches:${userId}`)
      this.matchHandlers.delete(userId)
      console.log(`🔕 Unsubscribed from matches for user ${userId}`)
    }
  }

  unsubscribeFromReadReceipts(matchId: string): void {
    const channel = this.channels.get(`reads:${matchId}`)
    if (channel) {
      channel.unsubscribe()
      this.channels.delete(`reads:${matchId}`)
      console.log(`🔕 Unsubscribed from read receipts for match ${matchId}`)
    }
  }

  // Unsubscribe from all channels
  unsubscribeAll(): void {
    this.channels.forEach((channel, key) => {
      channel.unsubscribe()
      console.log(`🔕 Unsubscribed from channel: ${key}`)
    })
    this.channels.clear()
    this.messageHandlers.clear()
    this.matchHandlers.clear()
  }

  // ============================================================================
  // Send message helper
  // ============================================================================
  
  async sendMessage(
    matchId: string,
    senderId: string,
    content: string,
    messageType: Message['message_type'] = 'text'
  ): Promise<Message | null> {
    try {
      const { data, error } = await this.supabase
        .from('messages')
        .insert({
          match_id: matchId,
          sender_id: senderId,
          content: content,
          message_type: messageType,
        })
        .select('*')
        .single()

      if (error) {
        console.error('❌ Erreur envoi message:', error)
        return null
      }

      console.log('✅ Message envoyé:', data)
      return data as Message
    } catch (error) {
      console.error('❌ Exception envoi message:', error)
      return null
    }
  }

  // ============================================================================
  // Mark messages as read helper
  // ============================================================================
  
  async markMessagesAsRead(
    matchId: string,
    userId: string,
    lastMessageId?: string
  ): Promise<boolean> {
    try {
      // Use the existing stored procedure if available
      const { error } = await this.supabase.rpc('mark_messages_read', {
        p_match_id: matchId,
        p_user_id: userId,
        p_last_message_id: lastMessageId,
      })

      if (error) {
        console.error('❌ Erreur marquage lecture:', error)
        return false
      }

      console.log('✅ Messages marqués comme lus')
      return true
    } catch (error) {
      console.error('❌ Exception marquage lecture:', error)
      return false
    }
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

// Example 1: Basic usage
export function basicRealtimeExample() {
  const messaging = new RealtimeMessaging(supabase)
  const currentUserId = 'user-uuid'
  const matchId = 'match-uuid'

  // Subscribe to new matches
  messaging.subscribeToMatches(currentUserId, (newMatch) => {
    console.log('🎉 New match notification:', newMatch)
    // Update UI, show notification, etc.
  })

  // Subscribe to messages for a specific match
  messaging.subscribeToMessages(matchId, (newMessage) => {
    console.log('💬 New message:', newMessage)
    // Update chat UI, play sound, etc.
    
    // Mark as read if user is viewing this conversation
    if (document.hasFocus() && isViewingMatch(matchId)) {
      messaging.markMessagesAsRead(matchId, currentUserId, newMessage.id)
    }
  })

  // Subscribe to read receipts
  messaging.subscribeToReadReceipts(matchId, (readReceipt) => {
    console.log('📖 Read receipt:', readReceipt)
    // Update UI to show read status
  })

  // Cleanup on component unmount
  return () => {
    messaging.unsubscribeAll()
  }
}

// Helper function (implement according to your UI logic)
function isViewingMatch(matchId: string): boolean {
  // Return true if user is currently viewing this match conversation
  return window.location.pathname.includes(matchId)
}

// Example 2: React Hook integration (preview)
export function useRealtimeMessaging(matchId: string, currentUserId: string) {
  // This would be implemented as a React Hook
  // See react-messaging-hooks.ts for full implementation
}

export default RealtimeMessaging
