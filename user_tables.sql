WITH user_group_table AS (
    SELECT
      f.follower_id,
      coalesce(listagg(g.name, ', ') WITHIN GROUP (ORDER BY f.follower_id)) AS group_list,
      coalesce(listagg(g.description, ', ') WITHIN GROUP (ORDER BY f.follower_id)) AS description_list,
      coalesce(listagg(g.blurb, ', ') WITHIN GROUP (ORDER BY f.follower_id)) AS blurb_list

    FROM mena_public.follows f
      LEFT JOIN mena_public.groups g ON (f.followable_id = g.id)
    WHERE f.follower_type = 'User' AND f.followable_type = 'Group'
    GROUP BY f.follower_id

  ),
    user_tag_table AS (
      SELECT
        tg.taggable_id,
        coalesce(listagg(t.name, ', ') WITHIN GROUP (ORDER BY tg.taggable_id)) AS tag_list,
        coalesce(listagg(tg.context, ', ') WITHIN GROUP (ORDER BY tg.taggable_id)) AS tag_context_list

      FROM mena_public.taggings tg
        LEFT JOIN mena_public.tags t ON (t.id = tg.tag_id)
        WHERE tg.taggable_type = 'User'

      GROUP BY tg.taggable_id
  ),

    company_tag_table AS (
      SELECT
        tg.taggable_id,
        coalesce(listagg(t.name, ', ') WITHIN GROUP (ORDER BY tg.taggable_id)) AS tag_list,
        coalesce(listagg(tg.context, ', ') WITHIN GROUP (ORDER BY tg.taggable_id)) AS tag_context_list

      FROM mena_public.taggings tg
        LEFT JOIN mena_public.tags t ON (t.id = tg.tag_id)
        WHERE tg.taggable_type = 'User'

      GROUP BY tg.taggable_id
  ),

    post_counts AS (
      SELECT poster_user_id, count(DISTINCT post_id) as total_posts
      FROM dw.mv_post_interactions
      GROUP BY poster_user_id
  ),

    interaction_counts AS (
      SELECT interaction_user_id, count(interaction_id) as total_interactions
      FROM dw.mv_post_interactions
      WHERE interaction_type IN ('Comment', 'Like') AND interaction_user_id IS NOT NULL
      GROUP BY interaction_user_id
  ),
    users AS (
      SELECT
        u.id,
        u.name,
        u.created_at  AS user_created_at,
        u.gender,
        u.kind,
        u.bio         AS user_bio,
        u.title,
        u.floor,
        u.location_id,
        u.home_location_id,
        u.websites,
        u.language_preference,

        l.name        AS office_name,
        l.description AS office_description,
        l.created_at  AS office_started,
        l.region_id,
        l.city,
        l.state,
        l.zip,
        l.country,
        l.active_for_anywhere,
        l.active,
        l.opened_on,
        l.after_hours_enabled,

        c.company_uuid,
        t.tag_list as user_tags,
        t.tag_context_list as user_tag_context,

        g.group_list,
        g.description_list,
        g.blurb_list,

        p.total_posts,

        i.total_interactions

      FROM mena_public.users u
        LEFT JOIN mena_public.locations l ON (u.location_id = l.id)
        LEFT JOIN dw.mv_company_user c ON (c.user_uuid = u.uuid)
        LEFT JOIN user_tag_table t ON (u.id = t.taggable_id)
        LEFT JOIN user_group_table g on (g.follower_id = u.id)
        LEFT JOIN post_counts p on (p.poster_user_id = u.id)
        LEFT JOIN interaction_counts i on (i.interaction_user_id = u.id)

      WHERE l.country = 'United States'
  ),

    companies AS (

      SELECT
        c.name          AS company_name,
        c.id            AS company_id,
        c.uuid          AS company_uuid,
        c.industry      AS company_industry,
        c.bio           AS company_bio,
        c.tagline       AS company_tagline,
        c.current_location_id,
        c.created_at    AS company_created_at,
        c.updated_at,
        c.number_of_employees,
        c.founding_date AS company_founded_on,
        c.city          AS company_city,
        c.region        AS company_region,
        c.country       AS company_country,

--         CASE WHEN c.avatar_file_name ISNULL THEN 0 ELSE 1 END      AS company_has_profile_pic,
--         CASE WHEN c.cover ISNULL THEN 0 ELSE 1 END      AS company_has_cover_pic,
        t.tag_list as company_tags,
        t.tag_context_list as company_tag_context

      FROM mena_public.companies c
        LEFT JOIN company_tag_table t ON (c.id = t.taggable_id)
  )

SELECT u.*, c.*
FROM users u
  LEFT JOIN companies c ON (u.company_uuid = c.company_uuid)
