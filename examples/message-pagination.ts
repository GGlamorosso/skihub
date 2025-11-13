// CrewSnow Message Pagination Implementation
// Two strategies: Offset-based and Cursor-based pagination

import { SupabaseClient } from '@supabase/supabase-js'

export interface Message {
  id: string
  match_id: string
  sender_id: string
  content: string
  message_type: 'text' | 'image' | 'location' | 'system'
  created_at: string
  is_read: boolean
  read_at?: string
  // Joined fields
  sender_username?: string
}

export interface PaginationResult<T> {
  data: T[]
  hasMore: boolean
  total?: number
  nextCursor?: string
  currentPage?: number
}

// ============================================================================
// 4. PAGINATION DES MESSAGES - DEUX STRATEGIES
// ============================================================================

export class MessagePagination {
  private supabase: SupabaseClient

  constructor(supabaseClient: SupabaseClient) {
    this.supabase = supabaseClient
  }

  // ============================================================================
  // STRATEGY 1: Pagination par offset (plus simple, moins performante)
  // ============================================================================
  
  async getMessagesByOffset(
    matchId: string,
    page: number = 0,
    limit: number = 50
  ): Promise<PaginationResult<Message>> {
    try {
      const offset = page * limit

      // Requête selon spécification:
      // SELECT * FROM messages WHERE match_id = $1 ORDER BY created_at DESC LIMIT 50 OFFSET $2
      const { data, error, count } = await this.supabase
        .from('messages')
        .select(`
          *,
          sender:users(username)
        `, { count: 'exact' })
        .eq('match_id', matchId)
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1)

      if (error) {
        console.error('❌ Erreur pagination offset:', error)
        return { data: [], hasMore: false }
      }

      // Transform data to include sender_username
      const messages: Message[] = data.map(msg => ({
        ...msg,
        sender_username: msg.sender?.username,
        sender: undefined, // Remove nested object
      }))

      const hasMore = count ? offset + limit < count : false

      return {
        data: messages,
        hasMore,
        total: count || 0,
        currentPage: page,
      }
    } catch (error) {
      console.error('❌ Exception pagination offset:', error)
      return { data: [], hasMore: false }
    }
  }

  // ============================================================================
  // STRATEGY 2: Pagination par curseur (recommandée pour performance)
  // ============================================================================
  
  async getMessagesByCursor(
    matchId: string,
    beforeTimestamp?: string,
    limit: number = 50
  ): Promise<PaginationResult<Message>> {
    try {
      let query = this.supabase
        .from('messages')
        .select(`
          *,
          sender:users(username)
        `)
        .eq('match_id', matchId)
        .order('created_at', { ascending: false })
        .limit(limit + 1) // +1 to check if there are more

      // Requête selon spécification:
      // SELECT * FROM messages WHERE match_id = $1 AND created_at < $2 ORDER BY created_at DESC LIMIT 50
      if (beforeTimestamp) {
        query = query.lt('created_at', beforeTimestamp)
      }

      const { data, error } = await query

      if (error) {
        console.error('❌ Erreur pagination curseur:', error)
        return { data: [], hasMore: false }
      }

      // Check if there are more messages
      const hasMore = data.length > limit
      const messages = data.slice(0, limit) // Remove the extra message used for hasMore check

      // Transform data
      const transformedMessages: Message[] = messages.map(msg => ({
        ...msg,
        sender_username: msg.sender?.username,
        sender: undefined,
      }))

      // Next cursor is the created_at of the last message
      const nextCursor = transformedMessages.length > 0 
        ? transformedMessages[transformedMessages.length - 1].created_at 
        : undefined

      return {
        data: transformedMessages,
        hasMore,
        nextCursor,
      }
    } catch (error) {
      console.error('❌ Exception pagination curseur:', error)
      return { data: [], hasMore: false }
    }
  }

  // ============================================================================
  // ENHANCED CURSOR PAGINATION WITH DATABASE FUNCTION
  // ============================================================================

  async getMessagesByCursorOptimized(
    matchId: string,
    userId: string,
    beforeTimestamp?: string,
    limit: number = 50
  ): Promise<PaginationResult<Message>> {
    try {
      // Use the database function for optimal performance
      const { data, error } = await this.supabase.rpc('get_match_messages', {
        p_match_id: matchId,
        p_user_id: userId,
        p_limit: limit + 1,
        p_before_timestamp: beforeTimestamp || null,
      })

      if (error) {
        console.error('❌ Erreur fonction pagination:', error)
        return { data: [], hasMore: false }
      }

      const hasMore = data.length > limit
      const messages = data.slice(0, limit)
      const nextCursor = messages.length > 0 ? messages[messages.length - 1].created_at : undefined

      return {
        data: messages,
        hasMore,
        nextCursor,
      }
    } catch (error) {
      console.error('❌ Exception fonction pagination:', error)
      return { data: [], hasMore: false }
    }
  }

  // ============================================================================
  // INFINITE SCROLL HELPER
  // ============================================================================
  
  async loadMoreMessages(
    matchId: string,
    currentMessages: Message[],
    strategy: 'offset' | 'cursor' = 'cursor'
  ): Promise<Message[]> {
    let newMessages: Message[] = []

    if (strategy === 'offset') {
      const currentPage = Math.floor(currentMessages.length / 50)
      const result = await this.getMessagesByOffset(matchId, currentPage + 1, 50)
      newMessages = result.data
    } else {
      // Cursor strategy (recommended)
      const lastMessage = currentMessages[currentMessages.length - 1]
      const beforeTimestamp = lastMessage?.created_at
      
      const result = await this.getMessagesByCursor(matchId, beforeTimestamp, 50)
      newMessages = result.data
    }

    // Merge with existing messages (remove duplicates)
    const existingIds = new Set(currentMessages.map(m => m.id))
    const filteredNewMessages = newMessages.filter(m => !existingIds.has(m.id))

    return [...currentMessages, ...filteredNewMessages]
  }

  // ============================================================================
  // REAL-TIME + PAGINATION COMBINED
  // ============================================================================
  
  // Complete messaging system with real-time updates and pagination
  setupCompleteMessaging(
    matchId: string,
    userId: string,
    onMessagesUpdate: (messages: Message[], unreadCount: number) => void
  ) {
    let currentMessages: Message[] = []

    // 1. Load initial messages
    this.getMessagesByCursor(matchId).then(result => {
      currentMessages = result.data
      this.getUnreadCount(matchId, userId).then(unreadCount => {
        onMessagesUpdate(currentMessages, unreadCount)
      })
    })

    // 2. Subscribe to real-time updates
    const channel = this.subscribeToMessages(matchId, (newMessage) => {
      // Add new message to current list
      currentMessages = [newMessage, ...currentMessages]
      
      // Update UI
      this.getUnreadCount(matchId, userId).then(unreadCount => {
        onMessagesUpdate(currentMessages, unreadCount)
      })
    })

    // 3. Return pagination and cleanup functions
    return {
      loadMore: () => this.loadMoreMessages(matchId, currentMessages, 'cursor'),
      markAsRead: () => this.markAsRead(matchId, userId),
      cleanup: () => {
        this.unsubscribeFromMessages(matchId)
      }
    }
  }

  // ============================================================================
  // UTILITY FUNCTIONS
  // ============================================================================

  private async getUnreadCount(matchId: string, userId: string): Promise<number> {
    try {
      const { data, error } = await this.supabase.rpc('get_unread_messages_count', {
        p_user_id: userId
      })

      if (error) {
        console.error('❌ Erreur comptage non-lus:', error)
        return 0
      }

      const matchData = data.find((item: any) => item.match_id === matchId)
      return matchData?.unread_count || 0
    } catch (error) {
      console.error('❌ Exception comptage non-lus:', error)
      return 0
    }
  }

  private async markAsRead(matchId: string, userId: string): Promise<void> {
    try {
      await this.supabase.rpc('mark_messages_read', {
        p_match_id: matchId,
        p_user_id: userId,
      })
      console.log('✅ Messages marqués comme lus')
    } catch (error) {
      console.error('❌ Erreur marquage lecture:', error)
    }
  }
}

// ============================================================================
// PERFORMANCE COMPARISON
// ============================================================================

export async function compareStrategies(
  pagination: MessagePagination,
  matchId: string,
  iterations: number = 10
) {
  console.log('📊 Comparing pagination strategies...')
  
  const offsetTimes: number[] = []
  const cursorTimes: number[] = []

  // Test offset strategy
  for (let i = 0; i < iterations; i++) {
    const start = Date.now()
    await pagination.getMessagesByOffset(matchId, i, 50)
    offsetTimes.push(Date.now() - start)
    
    // Small delay between tests
    await new Promise(resolve => setTimeout(resolve, 100))
  }

  // Test cursor strategy  
  let beforeTimestamp: string | undefined
  for (let i = 0; i < iterations; i++) {
    const start = Date.now()
    const result = await pagination.getMessagesByCursor(matchId, beforeTimestamp, 50)
    cursorTimes.push(Date.now() - start)
    
    beforeTimestamp = result.nextCursor
    await new Promise(resolve => setTimeout(resolve, 100))
  }

  const avgOffset = offsetTimes.reduce((a, b) => a + b, 0) / offsetTimes.length
  const avgCursor = cursorTimes.reduce((a, b) => a + b, 0) / cursorTimes.length

  console.log('📊 Performance Results:')
  console.log(`   Offset Strategy: ${avgOffset.toFixed(1)}ms average`)
  console.log(`   Cursor Strategy: ${avgCursor.toFixed(1)}ms average`)
  console.log(`   Performance gain: ${((avgOffset - avgCursor) / avgOffset * 100).toFixed(1)}%`)
  
  return {
    offset: { average: avgOffset, times: offsetTimes },
    cursor: { average: avgCursor, times: cursorTimes },
    improvement: (avgOffset - avgCursor) / avgOffset * 100
  }
}

// ============================================================================
// EXPORT DEFAULT
// ============================================================================

export default MessagePagination
