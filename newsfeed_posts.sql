WITH us_users AS (
    SELECT
      u.id,
      u.location_id,
      l.country,
      l.name as location_name,
      l.city as location_city

    FROM mena_public.users u
      LEFT JOIN mena_public.locations l ON (u.location_id = l.id)
    WHERE l.country = 'United States'
),
  total_table AS (
    SELECT
      p.interaction_user_id AS user,
      CASE WHEN p.photo ISNULL
        THEN 0
      ELSE 1 END            AS has_photo,
      p.post_id,
      p.post_created_at,
      p.post_content,
      p.interaction_id,
      p.interaction_content,
      p.interaction_type,
      p.interacted_at,
      p.interaction_user_id,

      u.location_id,
      u.location_name,
      u.location_city

    FROM dw.mv_post_interactions p
      LEFT JOIN us_users u ON (u.id = p.interaction_user_id)
    WHERE interaction_type IN ('Comment', 'Like') AND p.interaction_user_id IS NOT NULL

    UNION ALL

    SELECT
      p.poster_user_id AS user,
      CASE WHEN p.photo ISNULL
        THEN 0
      ELSE 1 END       AS has_photo,
      p.post_id,
      p.post_created_at,
      p.post_content,
      p.interaction_id,
      p.interaction_content,
      p.interaction_type,
      p.interacted_at,
      p.interaction_user_id,

      u.location_id,
      u.location_name,
      u.location_city


    FROM dw.mv_post_interactions p
      LEFT JOIN us_users u ON (u.id = p.poster_user_id)
    WHERE interaction_type IN ('Comment', 'Like') AND p.interaction_user_id IS NOT NULL
    GROUP BY p.poster_user_id,
      p.photo,
      p.post_id,
      p.post_created_at,
      p.post_content,
      p.interaction_id,
      p.interaction_content,
      p.interaction_type,
      p.interacted_at,
      p.interaction_user_id,

      u.location_id,
      u.location_name,
      u.location_city
  )

SELECT * FROM total_table
